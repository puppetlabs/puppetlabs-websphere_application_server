require 'spec_helper_acceptance'
require 'installer_constants'

describe 'IHS instance' do
  before(:all) do
    @agent = WebSphereHelper.get_ihs_server # gets beaker host with role 'ihs'
    WebSphereInstance.install(@agent) # run rendered websphere_class.erb with puppet agent
    WebSphereDmgr.install(@agent) # run rendered websphere_dmgr.erb with puppet agent
    @ihs_host     = @agent.hostname
    @listen_port  = 10080

    @manifest = WebSphereIhs.manifest(@agent, @listen_port)
    runner = BeakerAgentRunner.new
    @result = runner.execute_agent_on(@agent, @manifest) # run puppet agent on IHS host with rendered websphere_ihs.erb
  end

  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it_behaves_like 'an idempotent resource'

  it 'shall start an ihs server process' do
    sleep(10)
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
    sleep(10)
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

      @manifest = WebSphereIhs.manifest(@agent, @listen_port, status='stopped')
      runner = BeakerAgentRunner.new
      @result = runner.execute_agent_on(@agent, @manifest)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'shall not have processess listening on the configured port' do
      sleep(10)
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
