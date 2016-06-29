require 'spec_helper_acceptance'
require 'installer_constants'

describe 'jdbc layer is setup and working' do
  include_context "with a websphere base"
  include_context "with a websphere dmgr"

  before(:all) do
    hostname = WebSphereHelper.get_master

    @manifest = <<-MANIFEST
    websphere_jdbc_provider { '#{JDBCProviderConstants.jdbc_provider}':
      ensure         => 'present',
      dmgr_profile   => '#{JDBCProviderConstants.dmgr_profile}',
      profile_base   => '#{JDBCProviderConstants.profile_base}',
      user           => '#{JDBCProviderConstants.user}',
      scope          => '#{JDBCProviderConstants.scope}',
      cell           => '#{JDBCProviderConstants.cell}',
      node           => '#{hostname}',
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
      node                          => '#{hostname}',
      server                        => '#{JDBCProviderConstants.server}',
      jdbc_provider                 => '#{JDBCDatasourceConstants.jdbc_provider}',
      jndi_name                     => '#{JDBCDatasourceConstants.jndi_name}',
      data_store_helper_class       => '#{JDBCDatasourceConstants.data_store_helper_class}',
      container_managed_persistence => '#{JDBCDatasourceConstants.container_managed_persistence}',
      url                           => '#{JDBCDatasourceConstants.url}',
      description                   => '#{JDBCDatasourceConstants.description}',
    }

    MANIFEST
    @result = WebSphereHelper.agent_execute(@manifest)
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end

  it_behaves_like 'an idempotent resource'
end
