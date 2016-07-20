require 'spec_helper_acceptance'
require 'installer_constants'

shared_context 'with a websphere class' do
  before(:all) do
    @manifest = <<-MANIFEST
    # Organizational log locations
    file { [
      '/opt/log',
      '/opt/log/websphere',
      '/opt/log/websphere/appserverlogs',
      '/opt/log/websphere/applogs',
      '/opt/log/websphere/wasmgmtlogs',
    ]:
      ensure => 'directory',
      owner  => '#{WebSphereConstants.user}',
      group  => '#{WebSphereConstants.group}',
    }

    # Base stuff for WebSphere.  Specify a common user/group and the base
    # directory to where we want things to live.  Make sure the
    # InstallationManager is managed before we do this.
    class { '#{WebSphereConstants.class_name}':
      user     => '#{WebSphereConstants.user}',
      group    => '#{WebSphereConstants.group}',
      base_dir => '#{WebSphereConstants.base_dir}',
    }

    #{WebSphereConstants.class_name}::instance { '#{WebSphereConstants.instance_name}':
      target       => '#{WebSphereConstants.instance_base}',
      package      => '#{WebSphereConstants.package_name}',
      version      => '#{WebSphereConstants.package_version}',
      profile_base => '#{WebSphereConstants.profile_base}',
      repository   => "#{WebSphereConstants.repository}",
      user         => '#{WebSphereConstants.user}',
      group        => '#{WebSphereConstants.group}',
    }

    ibm_pkg { '#{FixpackConstants.name}':
      ensure        => 'present',
      package       => '#{WebSphereConstants.package_name}',
      version       => '#{FixpackConstants.version}',
      repository    => '#{FixpackConstants.repository}',
      target        => '#{WebSphereConstants.instance_base}',
      package_owner => '#{WebSphereConstants.user}',
      package_group => '#{WebSphereConstants.group}',
      require       => Websphere_application_server::Instance['#{WebSphereConstants.instance_name}'],
    }

    ibm_pkg { '#{JavaInstallerConstants.java7_name}':
      ensure        => 'present',
      package       => '#{JavaInstallerConstants.java7_package}',
      version       => '#{JavaInstallerConstants.java7_version}',
      repository    => "#{JavaInstallerConstants.java7_installer}/repository.config",
      target        => '#{WebSphereConstants.instance_base}',
      package_owner => '#{WebSphereConstants.user}',
      package_group => '#{WebSphereConstants.group}',
      require       => Ibm_pkg['#{FixpackConstants.name}'],
    }
    MANIFEST
    @result = WebSphereHelper.agent_execute(@manifest)
  end

  it 'should run successfully' do
    expect(@result.exit_code).to eq 2
  end
end
