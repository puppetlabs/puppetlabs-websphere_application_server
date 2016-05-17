require 'spec_helper'
describe 'websphere_application_server' do

  let(:facts) do
    {
      :concat_basedir => '/dne',
      :osfamily       => 'Debian',
    }
  end

  context 'with default parameters' do
    it { is_expected.to contain_class('websphere_application_server') }
  end
end
