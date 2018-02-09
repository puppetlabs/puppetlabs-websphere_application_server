
shared_examples 'a running dmgr' do |profile_base, dmgr_title|
  before(:all) do
    @dmgr_result     = on(@agent, "#{profile_base}/#{dmgr_title}/bin/serverStatus.sh -all -profileName #{dmgr_title} |  grep 'The Deployment Manager'", :acceptable_exit_codes => [0,1])
    @ws_admin_result = on(@agent, "#{profile_base}/#{dmgr_title}/bin/wsadmin.sh -lang jython -c \"AdminConfig.getid('/ServerCluster: #{WebSphereConstants.cluster_member}/')\"", :acceptable_exit_codes => [0,1,103])
  end

  it 'should be contactable' do
    results = @dmgr_result.stdout.split( /\r?\n/ )
    expect(results.size).to be 1
    expect(results[0]).to match(/^ADMU.*:.*dmgr.*STARTED$/)
  end

  it 'should be running a cluster' do
    expect(@ws_admin_result.stdout).to match(/^WASX.*:.*is: DeploymentManager/)
  end
end

shared_examples 'a stopped dmgr' do |profile_base, dmgr_title|
  before(:all) do
    @dmgr_result     = on(@agent, "#{profile_base}/#{dmgr_title}/bin/serverStatus.sh -all -profileName #{WebSphereConstants.dmgr_title} |  grep 'The Deployment Manager'", :acceptable_exit_codes => [0,1])
    @ws_admin_result = on(@agent, "#{profile_base}/#{dmgr_title}/bin/wsadmin.sh -lang jython -c \"AdminConfig.getid('/ServerCluster: #{WebSphereConstants.cluster_member}/')\"", :acceptable_exit_codes => [0,1,103])
  end

  it 'should not be contactable' do
    results = @dmgr_result.stdout.split( /\r?\n/ )
    expect(results[0]).to match(/^ADMU.*:.* The Deployment Manager \"dmgr\" cannot be reached/)
  end

  it 'should not be a cluster' do
    expect(@ws_admin_result.stdout).to match(/^WASX.*:.*Error creating \"SOAP\" connection to host \"localhost\"/)
  end
end
