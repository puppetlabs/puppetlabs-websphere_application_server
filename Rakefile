require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('relative')
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_documentation')
PuppetLint.configuration.send('disable_single_quote_string_with_variables')
PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp"]

# Use our own metadata task so we can ignore the non-SPDX PE licence
Rake::Task[:metadata].clear
desc "Check metadata is valid JSON"
task :metadata do
  sh "bundle exec metadata-json-lint metadata.json --no-strict-license"
end

# Repeat the override of the metadata linting metadata_lint task.
Rake::Task[:metadata_lint].clear
desc "Check metadata is valid JSON"
task :metadata_lint do
  sh "bundle exec metadata-json-lint metadata.json --no-strict-license"
end

desc "Run syntax, lint, and spec tests."
task :test => [
  :metadata,
  :syntax,
  :lint,
  :spec,
]
