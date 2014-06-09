#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'logger'
require 'optparse'
require 'pp'

module Ubiquity

  module Orchestrator

    class HTTPHandler

      DEFAULT_HOST_ADDRESS = 'localhost'
      DEFAULT_PORT = 3000

      attr_accessor :logger, :log_request_body, :log_response_body, :log_pretty_print_body

      attr_reader :http

      attr_accessor :cookie

      # @param [Hash] args
      # @option params [Logger] :logger
      # @option params [String] :log_to
      # @option params [Integer] :log_level
      # @option params [String] :host_address
      # @option params [Integer] :port
      def initialize(args = {})
        @logger = args[:logger] ? args[:logger].dup : Logger.new(args[:log_to] || STDOUT)
        logger.level = args[:log_level] if args[:log_level]

        hostname = args[:host_address] || DEFAULT_HOST_ADDRESS
        port = args[:host_port] || args[:port] || DEFAULT_PORT
        @http = Net::HTTP.new(hostname, port)
        @log_request_body = args[:log_request_body]
        @log_response_body = args[:log_response_body]
        @log_pretty_print_body = args[:log_pretty_print_body]
      end # initialize

      def http=(new_http)
        @to_s = nil
        @http = new_http
      end # http=

      # Formats a HTTPRequest or HTTPResponse body for log output.
      # @param [HTTPRequest|HTTPResponse] obj
      # @return [String]
      def format_body_for_log_output(obj)
        #obj.body.inspect
        output = ''
        if obj.content_type == 'application/json'
          if @log_pretty_print_body
            output << "\n"
            output << JSON.pretty_generate(JSON.parse(obj.body))
            return output
          else
            return obj.body
          end
        else
          return obj.body.inspect
        end
      end # pretty_print_body

      # Performs final processing of a request then executes the request and returns the response.
      #
      # Debug output for all requests and responses is also handled by this method.
      # @param [HTTPRequest] request
      def process_request(request)
        request['User-Agent'] = "Ruby/#{RUBY_VERSION}"

        request['Cookie'] = cookie if cookie
        logger.debug { redact_passwords(%(REQUEST: #{request.method} #{to_s}#{request.path} HEADERS: #{request.to_hash.inspect} #{log_request_body and request.request_body_permitted? ? "BODY: #{format_body_for_log_output(request)}" : ''})) }

        response = http.request(request)
        logger.debug { %(RESPONSE: #{response.inspect} HEADERS: #{response.to_hash.inspect} #{log_response_body and response.respond_to?(:body) ? "BODY: #{format_body_for_log_output(response)}" : ''}) }

        response
      end # process_request

      # Creates a HTTP DELETE request and passes it to {#process_request} for final processing and execution.
      # @param [String] path
      # @param [Hash] headers
      def delete(path, headers = { })
        http_to_s = to_s
        path = path.sub(http_to_s) if path.start_with?(http_to_s)
        path = "/#{path}" unless path.start_with?('/')
        request = Net::HTTP::Delete.new(path, headers)
        process_request(request)
      end # delete

      # Creates a HTTP GET request and passes it to {#process_request} for final processing and execution.
      # @param [String] path
      # @param [Hash] headers
      def get(path, headers = { })
        http_to_s = to_s
        path = path.sub(http_to_s, '') if path.start_with?(http_to_s)
        path = "/#{path}" unless path.start_with?('/')
        request = Net::HTTP::Get.new(path, headers)
        process_request(request)
      end # get

      # Processes put and post request bodies based on the request content type and the format of the data
      # @param [HTTPRequest] request
      # @param [Hash|String] data
      def process_put_and_post_requests(request, data)
        content_type = request['Content-Type'] ||= 'application/x-www-form-urlencoded'
        case content_type
          when 'application/x-www-form-urlencoded'; request.form_data = data
          when 'application/json'; request.body = (data.is_a?(Hash) or data.is_a?(Array)) ? JSON.generate(data) : data
          else
            #data = data.to_s unless request.body.is_a?(String)
            request.body = data
        end
        process_request(request)
      end # process_form_request

      # Creates a HTTP POST request and passes it on for execution
      # @param [Hash] headers
      def post(path, data, headers = { })
        path = "/#{path}" unless path.start_with?('/')
        request = Net::HTTP::Post.new(path, headers)
        process_put_and_post_requests(request, data)
      end # post

      # Creates a HTTP PUT request and passes it on for execution
      # @param [String] path
      # @param [String|Hash] data
      # @param [Hash] headers
      def put(path, data, headers = { })
        path = "/#{path}" unless path.start_with?('/')
        request = Net::HTTP::Put.new(path, headers)
        process_put_and_post_requests(request, data)
      end # post

      #def post_form_multipart(path, data, headers)
      #  #headers['Cookie'] = cookie if cookie
      #  #path = "/#{path}" unless path.start_with?('/')
      #  #request = Net::HTTP::Post.new(path, headers)
      #  #request.body = data
      #  #process_request(request)
      #end # post_form_multipart

      # Looks for passwords in a string and redacts them.
      #
      # @param [String] string
      # @return [String]
      def redact_passwords(string)
        string.sub!(/password((=.*)(&|$)|("\s*:\s*".*")(,|\s*|$))/) do |s|
          if s.start_with?('password=')
            _, remaining_string = s.split('&', 2)
            password_mask       = "password=*REDACTED*#{remaining_string ? "&#{redact_passwords(remaining_string)}" : ''}"
          else
            _, remaining_string = s.split('",', 2)
            password_mask       = %(password":"*REDACTED*#{remaining_string ? %(",#{redact_passwords(remaining_string)}) : '"'})
          end
          password_mask
        end
        string
      end # redact_passwords

      # Returns the connection information in a URI format.
      # @return [String]
      def to_s
        @to_s ||= "http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}"
      end # to_s

    end # HTTPHandler

    class << self

      attr_accessor :logger, :http

      def new(args = { })
        initialize(args)
        self.dup
      end

      def initialize(args = {})
        @logger = args[:logger] ? args[:logger].dup : Logger.new(args[:log_to] || STDOUT)
        logger.level = args[:log_level] if args[:log_level]

        @parse_response = args[:parse_response]

        initialize_http_handler(args)
      end # initialize

      # Sets the AdobeAnywhere connection information.
      # @see HTTPHandler#new
      def initialize_http_handler(args = {})
        @http = HTTPHandler.new(args)
        logger.debug { "Connection Set: #{http.to_s}" }
      end # connect

      def work_order_initiate(workflow_id, external_parameters = { }, options = { })
        query = options[:query] || { }
        query[:login] ||= options[:username] || 'admin'
        query[:password] ||= options[:password] || 'password'
        query['work_order[workflow_id]'] = workflow_id

        external_parameters.each do |k,v|
          query["external_parameters[#{k}]"] = v
        end

        http.post('aspera/orchestrator/work_orders/initiate/xml', query)

      end

    end

  end

end

def orchestrator; @orchestrator end

def initialize_orchestrator(args = { })
  @orchestrator = Ubiquity::Orchestrator.new(args)
end

def initialize_work_order(workflow_id = workflow_id, external_parameters = external_parameters, options = { })
  orchestrator.work_order_initiate(workflow_id, external_parameters, options)
end

def submit_file_path_to_workflow(file_path, args = { })
  workflow_id = args[:workflow_id]
  file_path_parameter_name = args[:file_path_parameter_name]
  external_parameters = args[:external_arguments]
  external_parameters[file_path_parameter_name] = file_path
  initialize_work_order(workflow_id, external_parameters, args)
end

@options = { }
def options; @options end

op = OptionParser.new
op.on('--host-address ADDRESS', 'The server address of the Orchestrator server.') { |v| options[:host_address] = v }
op.on('--host-port PORT', 'The port to use when communicating with the Orchestrator server.') { |v| options[:host_port] = v }
op.on('--username USERNAME', 'The username to use when communicating with the Orchestrator server.') { |v| options[:username] = v }
op.on('--password PASSWORD', 'The password to use when communicating with the Orchestrator server.') { |v| options[:password] = v }
op.on('--workflow-id ID', 'The id of the workflow to run.') { |v| options[:workflow_id] = v }
op.on('--additional-arguments JSON', 'A JSON Hash of arguments to submit as arguments to the workflow.') { |v| options[:additional_arguments] = v }
op.on('--help', 'Display this message.') { puts op; exit; }

initial_arguments = ARGV.dup
remaining_arguments = initial_arguments.dup
op.parse!(remaining_arguments)

args = {
  :log_request_body => true,
  :log_response_body => true,
  :log_pretty_print_body => true,
}

additional_arguments_json = options.delete(:additional_arguments) { '{}' }
additional_arguments = JSON.parse(additional_arguments_json)
additional_arguments = { } unless additional_arguments.is_a?(Hash)
workflow_id = options[:workflow_id]

abort("workflow-id is a required argument.\n#{op.to_s}") unless workflow_id

initialize_orchestrator(args.merge(options))

initialize_work_order(workflow_id, additional_arguments, options)
