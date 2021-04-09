# frozen_string_literal: true

shared_examples 'an idempotent resource' do
  it 'runs without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'runs a second time without changes' do
    runner = LitmusAgentRunner.new
    second_result = runner.execute_agent_on(@agent, @manifest)
    log_stdout(second_result.stdout) unless [0, 2].include?(second_result.exit_code)
    expect(second_result.exit_code).to eq 0
  end
end
