require 'spec_helper_acceptance'
require 'installer_constants'

describe 'IHS instance' do
  before(:all) do
    @agent = WebSphereHelper.get_ihs_server
    WebSphereInstance.install(@agent)
    WebSphereDmgr.install(@agent)
    @ihs_host     = @agent.hostname
    @listen_port  = 10080

    #create appserver profile manifest:
    @manifest = <<-MANIFEST
      class { 'websphere_application_server':
        user     => "#{WebSphereConstants.user}",
        group    => "#{WebSphereConstants.group}",
        base_dir => "#{WebSphereConstants.base_dir}",
      }

      websphere_application_server::ihs::instance { '#{IhsInstance.ihs_target}':
        target           => "#{WebSphereConstants.base_dir}/#{IhsInstance.ihs_target}",
        package          => "#{IhsInstance.package_ihs}",
        version          => "#{WebSphereConstants.package_version}",
        repository       => '/opt/QA_resources/ibm_websphere/ihs_ilan/repository.config',
        install_options  => '-properties user.ihs.httpPort=80',
        manage_user      => false,
        manage_group     => false,
        log_dir          => '/opt/log/websphere/httpserver',
        admin_username   => 'httpadmin',
        admin_password   => 'password',
        webroot          => '/opt/web',
      }

      ibm_pkg { 'Plugins':
        ensure     => 'present',
        target     => "#{WebSphereConstants.base_dir}/Plugins",
        repository => '/opt/QA_resources/ibm_websphere/plg_ilan/repository.config',
        package    => "#{IhsInstance.package_plugin}",
        version    => "#{WebSphereConstants.package_version}",
        require    => Websphere_application_server::Ihs::Instance['#{IhsInstance.ihs_target}'],
      }

      websphere_application_server::ihs::server { 'ihs_server':
        target      => "#{WebSphereConstants.base_dir}/#{IhsInstance.ihs_target}",
        log_dir     => '/opt/log/websphere/httpserver',
        plugin_base => "#{WebSphereConstants.base_dir}/Plugins",
        dmgr_host    => #{IhsInstance.dmgr_host},
        cell        => "#{WebSphereConstants.cell}",
        httpd_config => "#{WebSphereConstants.base_dir}/#{IhsInstance.ihs_target}/conf/httpd_test.conf",
        access_log  => '/opt/log/websphere/httpserver/access_log',
        error_log   => '/opt/log/websphere/httpserver/error_log',
        listen_port => "#{@listen_port}",
        require     => Ibm_pkg['Plugins'],
      }
    MANIFEST
    runner = BeakerAgentRunner.new
    @result = runner.execute_agent_on(@agent, @manifest)
  end

  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it_behaves_like 'an idempotent resource'

  it 'shall start an ihs server process' do
    ports_ihs_listening = on(@agent, "lsof -ti :#{@listen_port}").stdout.split
    ihs_server_process = []
    ports_ihs_listening.each do |port|
      proc_result = on(@agent, "ps -elf | egrep \"#{port}(\ )+1 \"", :acceptable_exit_codes => [0,1])
      ihs_server_process.push(proc_result.stdout) unless proc_result.stdout.empty?
    end

    expect(ihs_server_process.length).to be 1
    expect(ihs_server_process[0]).to match(/(.*)\/HTTPServer\/bin\/httpd(.*)+/)
  end

  it 'shall be listening on the correct port' do
    ports_ihs_listening = on(@agent, "lsof -ti :#{@listen_port}").stdout.split
    expect(ports_ihs_listening.size).to eq 2
  end

  it 'shall respond to http queries' do
    on(@agent, "curl -s -w '%{http_code}' http://#{@agent}:#{@listen_port} | egrep \"<title>|200\"",:acceptable_exit_codes => [0,1]) do |response|
      response_lines = response.stdout.split( /\r?\n/ )
      expect([0, 2]).to include(response_lines.length)
      expect(response_lines[0]).to match(/^<title>IBM HTTP Server(.*)+<\/title>$/)
      expect(response_lines[1]).to match(/^200$/)
    end
  end

  context 'shall stop the IHS server' do
    before(:all) do
      @agent        = WebSphereHelper.get_ihs_server
      @ihs_host     = @agent.hostname
      @listen_port  = 10080

      @manifest = <<-MANIFEST
        class { 'websphere_application_server':
          user     => "#{WebSphereConstants.user}",
          group    => "#{WebSphereConstants.group}",
          base_dir => "#{WebSphereConstants.base_dir}",
        }

        websphere_application_server::ihs::instance { '#{IhsInstance.ihs_target}':
          target           => "#{WebSphereConstants.base_dir}/#{IhsInstance.ihs_target}",
          package          => "#{IhsInstance.package_ihs}",
          version          => "#{WebSphereConstants.package_version}",
          repository       => '/opt/QA_resources/ibm_websphere/ihs_ilan/repository.config',
          install_options  => '-properties user.ihs.httpPort=80',
          user             => "#{WebSphereConstants.user}",
          group            => "#{WebSphereConstants.group}",
          manage_user      => false,
          manage_group     => false,
          log_dir          => '/opt/log/websphere/httpserver',
          admin_username   => 'httpadmin',
          admin_password   => 'password',
          webroot          => '/opt/web',
        }

        ibm_pkg { 'Plugins':
          ensure     => 'present',
          target     => "#{WebSphereConstants.base_dir}/Plugins",
          repository => '/opt/QA_resources/ibm_websphere/plg_ilan/repository.config',
          package    => "#{IhsInstance.package_plugin}",
          version    => "#{WebSphereConstants.package_version}",
          require    => Websphere_application_server::Ihs::Instance['#{IhsInstance.ihs_target}'],
        }

        websphere_application_server::ihs::server { 'ihs_server':
          status      => 'stopped',
          target      => "#{WebSphereConstants.base_dir}/#{IhsInstance.ihs_target}",
          log_dir     => '/opt/log/websphere/httpserver',
          plugin_base => "#{WebSphereConstants.base_dir}/Plugins",
          dmgr_host    => #{IhsInstance.dmgr_host},
          cell        => "#{WebSphereConstants.cell}",
          httpd_config => "#{WebSphereConstants.base_dir}/#{IhsInstance.ihs_target}/conf/httpd_test.conf",
          access_log  => '/opt/log/websphere/httpserver/access_log',
          error_log   => '/opt/log/websphere/httpserver/error_log',
          listen_port => "#{@listen_port}",
          require     => Ibm_pkg['Plugins'],
        }
      MANIFEST
      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'shall not have processess listening on the configured port' do
      ports_ihs_listening = on(@agent, "lsof -ti :#{@listen_port}", :acceptable_exit_codes => [0,1]).stdout
      expect(ports_ihs_listening.empty?).to be true
    end

    it 'should run a second time without changes' do
      runner = BeakerAgentRunner.new
      second_result = runner.execute_agent_on(@agent, @manifest)
      expect(second_result.exit_code).to eq 2
    end
  end
end
