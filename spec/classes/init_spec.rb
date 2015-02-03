require 'spec_helper'
describe 'websphere' do

  context 'with default parameters' do
    it { should contain_class('websphere') }
  end

end
