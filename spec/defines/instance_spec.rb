require 'spec_helper'

describe 'websphere_application_server::instance' do

  context 'barebones' do
    describe 'passes user to ibm_pkg' do
      let(:title) { 'test' }
      let(:params) { {
                       'target'       => '/tmp/',
                       'package'      => 'com.ibm.websphere.NDTRIAL.v85',
                       'version'      => '8.5.5000.20130514_1044',
                       'profile_base' => '/opt/IBM/WebSphere/AppServer/profiles',
                       'repository'   => '/mnt/myorg/was/repository.config',
                     } }
      let(:pre_condition) {'include websphere_application_server' }

      it { is_expected.to compile }

      context 'default user' do
        it { is_expected.to contain_user('websphere') }
        it { is_expected.to contain_ibm_pkg('test').with({ 'user' => 'websphere' }) }
      end

      context 'custom user' do
        let(:test_user) { 'test-user-install' }
        let(:params) do
          super().merge({
                          'manage_user'      => true,
                          'user'             => test_user,
                        })
        end

        it { is_expected.to contain_user('websphere') }
        it { is_expected.to contain_ibm_pkg('test').with({ 'user' => test_user }) }
      end
    end
  end
end
