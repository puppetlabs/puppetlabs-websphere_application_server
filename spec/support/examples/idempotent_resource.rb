shared_examples 'an idempotent resource' do
  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'should run a second time without changes' do
    if @manifest.is_a? String
      second_result = execute_manifest(@manifest, beaker_opts)
    else
      second_result = @manifest.execute
    end
    expect(second_result.exit_code).to eq 0
  end
end
