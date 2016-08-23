require 'spec_helper_acceptance'
require 'installer_constants'

describe 'Create the IHS instance' do
  include_context "with a websphere class"
  include_context "with a websphere dmgr"

  before(:all) do
    @ihs_server   = WebSphereHelper.get_ihs_server
    @ihs_host     = @ihs_server.hostname
    @listen_port  = 10080

    # create appserver profile manifest:
    @manifest = <<-MANIFEST
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
    @result = WebSphereHelper.agent_execute(@manifest)
  end

  it 'should run without errors' do
    binding.pry
    expect(@result.exit_code).to eq 2
  end

  it_behaves_like 'an idempotent resource'

  it 'should start an ihs server process' do
    ports_ihs_listening = on(@ihs_server, "lsof -ti :#{@listen_port}").stdout.split
    ihs_server_process = []
    ports_ihs_listening.each do |port|
      proc_result = on(@ihs_server, "ps -elf | egrep \"#{port}(\ )+1 \"", :acceptable_exit_codes => [0,1])
      ihs_server_process.push(proc_result.stdout) unless proc_result.stdout.empty?
    end

    expect(ihs_server_process.length).to be 1
    expect(ihs_server_process[0]).to match(/(.*)\/HTTPServer\/bin\/httpd(.*)+/) # GH: use our Constants!
  end

  it 'should be listening on the correct port' do
    ports_ihs_listening = on(@ihs_server, "lsof -ti :#{@listen_port}").stdout.split
    expect(ports_ihs_listening.size).to eq 2
  end

  it 'should respond to http queries' do
    on(@ihs_server, "curl -s -w '%{http_code}' http://#{@ihs_host}:#{@listen_port} | egrep \"<title>|200\"",:acceptable_exit_codes => [0,1]) do |response|
      response_lines = response.stdout.split( /\r?\n/ )
      expect(response_lines.length).to eq 2
      expect(response_lines[0]).to match(/^<title>IBM HTTP Server(.*)+<\/title>$/)
      expect(response_lines[1]).to match(/^200$/)
    end
  end
end
