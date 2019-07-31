if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  require 'simplecov-console'
  require 'codecov'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::Codecov,
  ]
  SimpleCov.start do
    track_files 'lib/**/*.rb'

    add_filter '/spec'

    # do not track vendored files
    add_filter '/vendor'
    add_filter '/.vendor'

    # do not track gitignored files
    # this adds about 4 seconds to the coverage check
    # this could definitely be optimized
    add_filter do |f|
      # system returns true if exit status is 0, which with git-check-ignore means file is ignored
      system("git check-ignore --quiet #{f.filename}")
    end
  end
end

# @return [String] - the path to the fixtures directory
def fixtures_dir
  @fixtures_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

# @return [String] = the path the directory of external facterdb facts
def mock_facts
  @mock_facts ||= File.join(fixtures_dir, 'facterdb_facts')
end

# @return [Hash] - returns a hash of testable operating systems
# uncomment and replace empty hash
# modify to your liking, default to all supported
# operating systems defined in the metadata.json file
def test_on
  @test_on ||= {}
  # {hardwaremodels: ['x86_64'],
  # supported_os: [
  #     {
  #         'operatingsystem' => 'Ubuntu',
  #         'operatingsystemrelease' => ['14.04'],
  #     },
  # ]},
end

ENV['FACTERDB_SEARCH_PATHS'] = mock_facts
