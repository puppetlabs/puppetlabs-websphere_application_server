require 'spec_helper'

describe 'websphere_application_server::ihs::instance' do

  context 'barebones' do
    describe 'passes user to ibm_pkg' do
      let(:title) { 'test' }
      let(:params) { {
                       'target'       => '/tmp/',
                       'package'      => 'com.ibm.websphere.NDTRIAL.v85',
                       'version'      => '8.5.5000.20130514_1044',
                       'repository'   => '/mnt/myorg/was/repository.config',
                       'manage_user'  => false,
                       'manage_group' => false,
                     } }
      let(:pre_condition) {'include websphere_application_server' }

      it { is_expected.to compile }

      context 'default user' do
        it { is_expected.to contain_user('websphere') }
        it { is_expected.to contain_ibm_pkg('IHS test').with({ 'user' => 'websphere' }) }
      end

      context 'custom user' do
        let(:test_user) { 'test-user-install' }
        let(:params) do
          super().merge({
                          'user'         => test_user,
                          'manage_user'  => true,
                        })
        end

        it { is_expected.to contain_user('websphere') }
        it { is_expected.to contain_ibm_pkg('IHS test').with({ 'user' => test_user }) }
      end
    end
  end
end
