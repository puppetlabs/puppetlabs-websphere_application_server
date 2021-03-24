# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'IHS instance', :integration do
  before(:all) do
    @agent = WebSphereHelper.ihs_server
    @ws_manifest = WebSphereInstance.manifest(user: 'webadmin',
                                              group: 'webadmins')
    @dmgr_manifest = WebSphereDmgr.manifest(target_agent: @agent)
    @ihs_host     = @agent
    @listen_port  = 10_080

    @ihs_manifest = WebSphereIhs.manifest(user: 'webadmin',
                                          group: 'webadmins',
                                          target_agent: @agent,
                                          listen_port: @listen_port)
    runner = LitmusAgentRunner.new
    stdout = runner.execute_agent_on(@agent, @ws_manifest)
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    stdout = runner.execute_agent_on(@agent, @dmgr_manifest)
    log_stdout(stdout.stdout) unless [0, 2].include?(stdout.exit_code)
    @result = runner.execute_agent_on(@agent, @ihs_manifest)
    log_stdout(@result.stdout) unless [0, 2].include?(@result.exit_code)
    ENV['TARGET_HOST'] = @agent
  end

  it 'runs without errors' do
    expect(@result.exit_code).to eq 2
  end

  it_behaves_like 'an idempotent resource'

  it 'shall start an ihs server process' do
    sleep(10)
    ports_ihs_listening = Helper.instance.run_shell("lsof -ti :#{@listen_port}").stdout.split
    ihs_server_process = []
    ports_ihs_listening.each do |port|
      proc_result = Helper.instance.run_shell("ps -elf | egrep \"#{port}(\ )+1 \"", expect_failures: true)
      ihs_server_process.push(proc_result.stdout) unless proc_result.stdout.empty?
    end

    expect(ihs_server_process.length).to be 1
    expect(ihs_server_process[0]).to match(%r{(.*)/HTTPServer\/bin\/httpd(.*)+})
  end

  it 'shall be listening on the correct port' do
    sleep(10)
    ports_ihs_listening = Helper.instance.run_shell("lsof -ti :#{@listen_port}").stdout.split
    expect(ports_ihs_listening.size).to eq 2
  end

  it 'shall respond to http queries' do
    agent_fqdn = Helper.instance.run_shell('facter fqdn').stdout.delete("\n")
    Helper.instance.run_shell("curl -s -w '%{http_code}' http://#{agent_fqdn}:#{@listen_port} | egrep \"<title>|200\"") do |response|
      response_lines = response.stdout.split(%r{\r?\n})
      expected = [0, 2]
      expect(expected).to include(response_lines.length)
      expect(response_lines[0]).to match(%r{^<title>IBM HTTP Server(.*)+</title>$})
      expect(response_lines[1]).to match(%r{^200$})
    end
  end

  context 'shall stop the IHS server' do
    before(:all) do
      @agent        = WebSphereHelper.ihs_server
      @ihs_host     = @agent
      @listen_port  = 10_080

      @ihs_manifest = WebSphereIhs.manifest(user: 'webadmin',
                                            group: 'webadmins',
                                            target_agent: @agent,
                                            listen_port: @listen_port,
                                            status: 'stopped')
      runner = LitmusAgentRunner.new
      @result = runner.execute_agent_on(@agent, @ihs_manifest)
      log_stdout(@result.stdout) unless [0, 2].include?(@result.exit_code)
      ENV['TARGET_HOST'] = @agent
    end

    it 'runs without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'shall not have processess listening on the configured port' do
      sleep(10)
      ports_ihs_listening = Helper.instance.run_shell("lsof -ti :#{@listen_port}", expect_failures: true).stdout
      expect(ports_ihs_listening.empty?).to be true
    end

    it 'runs a second time without changes' do
      runner = LitmusAgentRunner.new
      second_result = runner.execute_agent_on(@agent, @ihs_manifest)
      log_stdout(second_result.stdout) unless [0, 2].include?(second_result.exit_code)
      expect(second_result.exit_code).to eq 2
    end
  end
end
