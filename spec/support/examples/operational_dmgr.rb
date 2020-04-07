
shared_examples 'a running dmgr' do |profile_base, dmgr_title|
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    ENV['TARGET_HOST'] = @agent
    @dmgr_result = Helper.instance.run_shell("#{profile_base}/#{dmgr_title}/bin/serverStatus.sh -all -profileName #{dmgr_title} |  grep 'The Deployment Manager'")
    @ws_admin_result = Helper.instance.run_shell("#{profile_base}/#{dmgr_title}/bin/wsadmin.sh -lang jython -c \"AdminConfig.getid('/ServerCluster: #{WebSphereConstants.cluster_member}/')\"")
  end

  it 'is contactable' do
    results = @dmgr_result.stdout.split(%r{\r?\n})
    expect(results.size).to be 1
    expect(results[0]).to match(%r{^ADMU.*:.*dmgr.*STARTED$})
  end

  it 'is running a cluster' do
    expect(@ws_admin_result.stdout).to match(%r{^WASX.*:.*is: DeploymentManager})
  end
end

shared_examples 'a stopped dmgr' do |profile_base, dmgr_title|
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    ENV['TARGET_HOST'] = @agent
    @dmgr_result = Helper.instance.run_shell("#{profile_base}/#{dmgr_title}/bin/serverStatus.sh -all -profileName #{WebSphereConstants.dmgr_title} |  grep 'The Deployment Manager'")
    @ws_admin_result = Helper.instance.run_shell("#{profile_base}/#{dmgr_title}/bin/wsadmin.sh -lang jython -c \"AdminConfig.getid('/ServerCluster: #{WebSphereConstants.cluster_member}/')\"", expect_failures: true) # rubocop:disable Metrics/LineLength
    @ws_admin_result.exit_code == %r{0,1,103}
  end

  it 'is not contactable' do
    results = @dmgr_result.stdout.split(%r{\r?\n})
    expect(results[0]).to match(%r{^ADMU.*:.* The Deployment Manager \"dmgr\" cannot be reached})
  end

  it 'is not a cluster' do
    expect(@ws_admin_result.stdout).to match(%r{^WASX.*:.*Error creating \"SOAP\" connection to host \"localhost\"})
  end
end
