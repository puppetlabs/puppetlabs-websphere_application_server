# frozen_string_literal: true

require 'spec_helper'

describe 'websphere_application_server::instance' do
  let(:pre_condition) { 'include websphere_application_server' }

  context 'installing websphere 9' do
    let(:title) { 'Installs WAS 9' }
    let(:params) do
      {
        target: '/opt/IBM/WebSphere/AppServer',
        repository: '/mnt/myorg/was/repository.config',
        package: 'com.ibm.websphere.ND.v90',
        version: '9.0.0.20160526_1854',
      }
    end

    describe 'happy path' do
      let(:params) do
        super().merge(
          jdk_package_name: 'com.ibm.websphere.IBMJAVA.v71',
          jdk_package_version: '7.1.2000.20141116_0823',
        )
      end

      it { is_expected.to compile }
    end

    describe 'without jdk specified' do
      it { is_expected.to raise_error Puppet::PreformattedError, %r{When installing WebSphere AppServer 9, you must specify a JDK} }
    end
  end
end
