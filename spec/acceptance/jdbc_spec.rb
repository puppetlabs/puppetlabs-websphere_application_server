require 'spec_helper_acceptance'
require 'installer_constants'

describe 'jdbc layer is setup and working' do
  before(:all) do
    @agent = WebSphereHelper.get_ihs_server
    @was_manifest = WebSphereInstance.manifest(user: 'webadmin',
                                               group: 'webadmins')
    @dmgr_manifest = WebSphereDmgr.manifest(target_agent: @agent,
                                            user: 'webadmin',
                                            group: 'webadmins')
    @hostname = @agent.hostname

    @manifest = <<-MANIFEST
    websphere_jdbc_provider { '#{JDBCProviderConstants.jdbc_provider}':
      ensure         => 'present',
      dmgr_profile   => '#{JDBCProviderConstants.dmgr_profile}',
      profile_base   => '#{JDBCProviderConstants.profile_base}',
      user           => '#{JDBCProviderConstants.user}',
      scope          => '#{JDBCProviderConstants.scope}',
      cell           => '#{JDBCProviderConstants.cell}',
      node_name      => '#{@hostname}',
      server         => '#{JDBCProviderConstants.server}',
      dbtype         => '#{JDBCProviderConstants.dbtype}',
      providertype   => '#{JDBCProviderConstants.providertype}',
      implementation => '#{JDBCProviderConstants.implementation}',
      description    => '#{JDBCProviderConstants.description}',
      classpath      => '#{JDBCProviderConstants.classpath}',
    }

    websphere_jdbc_datasource { '#{JDBCDatasourceConstants.jdbc_provider}':
      ensure                        => 'present',
      dmgr_profile                  => '#{JDBCProviderConstants.dmgr_profile}',
      profile_base                  => '#{JDBCProviderConstants.profile_base}',
      user                          => '#{JDBCProviderConstants.user}',
      scope                         => '#{JDBCProviderConstants.scope}',
      cell                          => '#{JDBCProviderConstants.cell}',
      node_name                     => '#{@hostname}',
      server                        => '#{JDBCProviderConstants.server}',
      jdbc_provider                 => '#{JDBCDatasourceConstants.jdbc_provider}',
      jndi_name                     => '#{JDBCDatasourceConstants.jndi_name}',
      data_store_helper_class       => '#{JDBCDatasourceConstants.data_store_helper_class}',
      container_managed_persistence => '#{JDBCDatasourceConstants.container_managed_persistence}',
      url                           => '#{JDBCDatasourceConstants.url}',
      description                   => '#{JDBCDatasourceConstants.description}',
    }

    MANIFEST
    runner = BeakerAgentRunner.new
    runner.execute_agent_on(@agent, @was_manifest)
    runner.execute_agent_on(@agent, @dmgr_manifest)
    @result = runner.execute_agent_on(@agent, @manifest)
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end

  it_behaves_like 'an idempotent resource'

  it 'should have installed the thin client datasource and provider' do
    @ws_admin_result = on(@agent, "su - webadmin -c \"#{WebSphereConstants.ws_admin} -lang jython -c \\\"print AdminConfig.list('DataSource',AdminConfig.getid('/Cell:#{JDBCProviderConstants.cell}/Node:#{@hostname}/'))\\\"\"", :acceptable_exit_codes => [0,1,103])
    results = @ws_admin_result.stdout.split( /\r?\n/ )
    expect(results.size).to eq 3
    expect(results[0]).to match(/^WASX.*:.*is: DeploymentManager/)
    expect(results[1]).to match(/^\"#{JDBCDatasourceConstants.jdbc_provider}.*#{JDBCProviderConstants.cell}\/nodes\/#{@hostname}.*#DataSource_.*/)
    expect(results[2]).to match(/^OTiSDataSource\(cells\/#{JDBCProviderConstants.cell}\/nodes\/#{@hostname}\|resources.xml#builtin_DataSource_.*/)
  end
end
