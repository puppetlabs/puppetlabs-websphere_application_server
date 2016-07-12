require 'spec_helper_acceptance'
require 'installer_constants'

describe 'add cluster members' do
  include_context "with a websphere base"
  include_context "with a websphere dmgr"

  context "Start testing...." do
    before(:all) do
      hostname = WebSphereHelper.get_master
     # member1 = WebSphereHelper.get_fresh_node('redhat-7-x86_64')
     # member2 = WebSphereHelper.get_fresh_node('centos-6-x86_64')

      it " explicitly" do
        @manifest = <<-MANIFEST
        ## Create  Application Server Profiles
        #{WebSphereConstants.class_name}::profile::appserver {"#{WebSphereConstants.appserver_title}_explicitly":
          instance_base => '#{WebSphereConstants.instance_base}',
          profile_base  => '#{JDBCProviderConstants.profile_base}',
          cell          => '#{JDBCProviderConstants.cell}',
          template_path => "#{WebSphereConstants.instance_base}/profileTemplates/managed",
          dmgr_host     => "#{hostname}.delivery.puppetlabs.net",
          node_name     => "#{hostname}",
          user          => '#{WebSphereConstants.user}',
          group         => '#{WebSphereConstants.group}',
        }
        ->
        ## Create a cluster member explicitly
        #{WebSphereConstants.class_name}::cluster::member { "#{WebSphereConstants.appserver_title}_explicitly":
          ensure       => 'present',
          cluster      => "#{WebSphereCluster.cluster_name}",
          node_name    => "#{hostname}",
          cell         => "#{WebSphereConstants.cell}",
          profile_base => "#{WebSphereConstants.profile_base}",
          dmgr_profile => "#{WebSphereConstants.dmgr_title}",
        }
        MANIFEST
        @result = WebSphereHelper.agent_execute(@manifest)
        expect(@result.exit_code).to eq 2
      end

      it " with exported resources" do
        @manifest = <<-MANIFEST
        #{WebSphereConstants.class_name}::profile::appserver {"#{WebSphereConstants.appserver_title}_exported_res":
          instance_base => '#{WebSphereConstants.instance_base}',
          profile_base  => '#{JDBCProviderConstants.profile_base}',
          cell          => '#{JDBCProviderConstants.cell}',
          template_path => "#{WebSphereConstants.instance_base}/profileTemplates/managed",
          dmgr_host     => "#{hostname}.delivery.puppetlabs.net",
          node_name     => "#{hostname}",
          user          => '#{WebSphereConstants.user}',
          group         => '#{WebSphereConstants.group}',
        }
        ->
        ## Create a cluster member with exported resource
        #{WebSphereConstants.class_name}::cluster::member { "#{WebSphereConstants.appserver_title}_exported_res":
        ensure       => 'present',
        cluster      => "#{WebSphereCluster.cluster_name}",
        node_name    => "#{hostname}",
        cell         => "#{WebSphereConstants.cell}",
        }
        MANIFEST
        @result = WebSphereHelper.agent_execute(@manifest)
        expect(@result.exit_code).to eq 2
      end

      it_behaves_like 'an idempotent resource'
    end
  end
end
