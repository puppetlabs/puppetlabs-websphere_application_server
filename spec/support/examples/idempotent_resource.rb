shared_examples 'an idempotent resource' do
  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'should run a second time without changes' do
    runner = BeakerAgentRunner.new
    second_result = runner.execute_agent_on(@agent, @manifest)
    expect(second_result.exit_code).to eq 0
  end
end
