require 'spec_helper'
describe 'websphere' do

  let(:facts) do
    {
      :concat_basedir => '/dne',
      :osfamily       => 'RedHat',
    }
  end

  context 'with default parameters' do
    it { should contain_class('websphere') }
  end

end
