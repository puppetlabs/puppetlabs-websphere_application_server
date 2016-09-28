require 'rake'
require 'parallel_tests'
require 'rototiller'

# We clear the Beaker rake tasks from spec_helper as they assume
# rspec-puppet and a certain filesystem layout
Rake::Task[:beaker_nodes].clear
Rake::Task[:beaker].clear

module ParallelTests
  module Tasks
    def self.parse_args(args)
      args = [args[:count], args[:options]]

      # count given or empty ?
      # parallel:spec[2,options]
      # parallel:spec[,options]
      count = args.shift if args.first.to_s =~ /^\d*$/
      num_processes = count.to_i unless count.to_s.empty?
      options = args.shift

      [num_processes, options.to_s]
    end
  end
end

namespace :parallel do
  desc "Run acceptance in parallel with parallel:acceptance[num_cpus]"
  task :acceptance, [:count, :options] do |t, args|
    ENV['BEAKER_TESTMODE'] = 'local'
    count, options = ParallelTests::Tasks.parse_args(args)
    executable = 'parallel_test'
    command = "#{executable} spec --type rspec " \
      "-n #{count} "                 \
      "--pattern 'spec/acceptance' " \
      "--test-options '#{options}'"
    abort unless system(command)
  end
end

PE_RELEASES = {
  '2016.1' => 'http://pe-releases.puppetlabs.lan/2016.1/',
}

rototiller_task :spec_prep do |t|
  t.add_env({:name => 'BEAKER_PE_DIR',
             :message => 'Puppet Enterprise source directory',
             :default => PE_RELEASES['2016.1']})

  t.add_env({:name => 'BEAKER_debug',
             :message => 'Beaker debug level',
             :default => 'false'})

  t.add_env({:name => 'BEAKER_set',
             :message => 'Beaker set. This defines what beaker nodeset will be used for the test',
             :default => "default"})

  t.add_env({:name => 'BEAKER_keyfile',
             :message => 'The keyfile is the rsa pem file used to connect to the vm test instances',
             :default => '~/.ssh/id_rsa-acceptance'})
end


desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance => [:spec_prep]) do |t|
  t.pattern = 'spec/acceptance'
end

namespace :acceptance do
  {
    :vagrant => [
      'ubuntu1404',
      'centos7',
      'centos6',
      'ubuntu1404m_debian7a',
      'ubuntu1404m_ubuntu1404a',
      'centos7m_centos7a',
      'centos6m_centos6a',
    ],
    :pooler => [
      'ubuntu1404',
      'centos7',
      'centos6',
      'ubuntu1404m_debian7a',
      'ubuntu1404m_ubuntu1404a',
      'centos7m_centos7a',
      'centos6m_centos6a',
      'rhel7',
      'rhel7m_scientific7a',
      'centos7m_windows2012a',
      'centos7m_windows2012r2a',
    ]
  }.each do |ns, configs|
    namespace ns.to_sym do
      configs.each do |config|
        PE_RELEASES.each do |version, pe_dir|
          desc "Run acceptance tests for #{config} on #{ns} with PE #{version}"
          RSpec::Core::RakeTask.new("#{config}_#{version}".to_sym => [:spec_prep]) do |t|
            t.pattern = 'spec/acceptance'
          end
        end
      end
    end
  end
end
