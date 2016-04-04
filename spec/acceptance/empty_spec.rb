require 'spec_helper_acceptance'

describe "empty spec" do
  it 'notifies' do
    pp = <<-EOS
      notify { 'hello': }
    EOS

    apply_manifest(pp, :catch_failures => true)
  end
end
