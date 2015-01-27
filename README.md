# Ubiquity Orchestrator Library and Command Line Utilities

## System Requirements
  
  - <a href="https://www.ruby-lang.org/en/installation/" target="_blank">Ruby 1.8.7 or Higher</a>
  - <a href="http://git-scm.com/book/en/Getting-Started-Installing-Git" target="_blank">Git</a> 
  - RubyGems
  - <a href="http://bundler.io/" target="_blank">Bundler</a>

## Prerequisites

### CentOS 6.4 or higher

    yum install git
    yum install ruby-devel
    yum install rubygems
    gem install bundler

### Mac OS X
    
    gem install bundler
    
## Installation

    git clone https://github.com/XPlatform-Consulting/ubiquity-orchestrator.git
    cd ubiquity-orchestrator
    bundle update

## Orchestrator Submit to Workflow Executable [bin/submit_to_workflow](./bin/submit_to_workflow)
An executable to initiate a work order

Usage: submit_to_workflow [options]

    --host-address ADDRESS       The server address of the Orchestrator server.
    --host-port PORT             The port to use when communicating with the Orchestrator server.
    --username USERNAME          The username to use when communicating with the Orchestrator server.
    --password PASSWORD          The password to use when communicating with the Orchestrator server.
    --request-path-prefix PREFIX The request path prefix.
                                  default: "aspera/orchestrator"
    --workflow-id ID             The id of the workflow to run.
    --additional-arguments JSON  A JSON Hash of arguments to submit as arguments to the workflow.
    --[no-]wait                  Will wait until the work order is completed.
                                  default: false
    --work-order-id ID           The ID of an existing work order.
    --help                       Display this message.

#### Example of Usage:

###### Accessing Help.
  ./submit_to_workflow --help
  
## Orchestrator Submit File Path to Workflow [bin/submit_file_path_to_workflow](./bin/submit_to_workflow)
An executable to submit the path to a file or the files within a directory to a workflow
 
Usage: submit_file_path_to_workflow [options]
        
    --host-address ADDRESS       The server address of the Orchestrator server.
    --host-port PORT             The port to use when communicating with the Orchestrator server.
    --username USERNAME          The username to use when communicating with the Orchestrator server.
    --password PASSWORD          The password to use when communicating with the Orchestrator server.
    --request-path-prefix PREFIX The request path prefix.
                                   default: "aspera/orchestrator"
    --workflow-id ID             The id of the workflow to run.
    --file-path-parameter-name NAME
                                 The name of the parameter to submit the file path to.
    --additional-arguments JSON  A JSON Hash of arguments to submit as arguments to the workflow.
    --help                       Display this message.

#### Example of Usage:

###### Accessing Help.
  ./submit_file_path_to_workflow --help
  
  
## Contributing

1. Fork it ( https://github.com/XPlatform-Consulting/ubiquity-orchestrator/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

