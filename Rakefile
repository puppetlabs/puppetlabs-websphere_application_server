require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

lint_exclude = [
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
  "examples/**/*",
]

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  # Pattern of files to ignore
  config.ignore_paths = lint_exclude

  # List of checks to disable
  config.disable_checks = [ '80chars', 'class_inherits_from_params_class' ]

  # Should the task fail if there were any warnings, defaults to false
  config.fail_on_warnings = true

  # Print out the context for the problem, defaults to false
  config.with_context = true

  # Format string for puppet-lint's output (see the puppet-lint help output
  # for details
  config.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"
end

PuppetLint.configuration.relative = true
PuppetSyntax.exclude_paths = lint_exclude


desc "Validate manifests, templates, and ruby files"
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['spec/**/*.rb','lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end
