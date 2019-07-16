require 'beaker-rspec'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

$LOAD_PATH << File.join(__dir__, 'acceptance/lib')
require 'solaris_util'

def beaker_opts
  { debug: true, trace: true, expect_failures: true, acceptable_exit_codes: (0...256) }
  # { expect_failures: true, acceptable_exit_codes: (0...256) }
end

def solaris_agents
  agents.select { |agent| agent['platform'].include?('solaris') }
end

RSpec.configure do |c|
  c.before :suite do
    unless ENV['BEAKER_provision'] == 'no'
      run_puppet_install_helper
      install_module_on(hosts)
      install_module_dependencies_on(hosts)
    end
  end
end
