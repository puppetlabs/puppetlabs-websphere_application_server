# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:websphere_namespace_binding) do
  @doc = <<-DOC
    @summary This manages WebSphere namespace bindings.
    @example
      websphere_namespace_binding { 'corbaPuppetTest':
        ensure                        => 'present',
        dmgr_profile                  => 'PROFILE_DMGR_01',
        profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
        user                          => 'webadmin',
        cell                          => 'CELL_01',
        node_name                     => 'AppNode01',
        cluster                       => 'TEST_CLUSTER',
        scope                         => 'cluster',
        binding_type                  => 'corba',
        name_in_name_space            => 'corbaPuppetTestNameInNameSpace',
        string_to_bind                => undef,
        ejb_jndi_name                 => undef,
        application_server_name       => undef,
        application_node_name         => undef,
        corbaname_url                 => 'corba.example.com',
        federated_context             => false,
        provider_url                  => undef,
        initial_context_factory       => undef,
        jndi_name                     => undef,
      }
      websphere_namespace_binding { 'ejbPuppetTest':
        ensure                        => 'present',
        dmgr_profile                  => 'PROFILE_DMGR_01',
        profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
        user                          => 'webadmin',
        cell                          => 'CELL_01',
        node_name                     => 'AppNode01',
        cluster                       => 'TEST_CLUSTER',
        scope                         => 'cluster',
        binding_type                  => 'ejb',
        name_in_name_space            => 'ejbPuppetNameInNameSpace',
        string_to_bind                => undef,
        ejb_jndi_name                 => 'jndiNameExample',
        application_server_name       => 'example.com',
        application_node_name         => undef,
        corbaname_url                 => undef,
        federated_context             => undef,
        provider_url                  => undef,
        initial_context_factory       => undef,
        jndi_name                     => undef,
      }
      websphere_namespace_binding { 'stringPuppetTest':
        ensure                        => 'present',
        dmgr_profile                  => 'PROFILE_DMGR_01',
        profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
        user                          => 'webadmin',
        cell                          => 'CELL_01',
        node_name                     => 'AppNode01',
        cluster                       => 'TEST_CLUSTER',
        scope                         => 'cluster',
        binding_type                  => 'string',
        name_in_name_space            => 'stringPuppetNameInNameSpace',
        string_to_bind                => 'PuppetString',
        ejb_jndi_name                 => undef,
        application_server_name       => undef,
        application_node_name         => undef,
        corbaname_url                 => undef,
        federated_context             => undef,
        provider_url                  => undef,
        initial_context_factory       => undef,
        jndi_name                     => undef,
      }
      websphere_namespace_binding { 'indirectPuppetTest':
        ensure                        => 'present',
        dmgr_profile                  => 'PROFILE_DMGR_01',
        profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
        user                          => 'webadmin',
        cell                          => 'CELL_01',
        node_name                     => 'AppNode01',
        cluster                       => 'TEST_CLUSTER',
        scope                         => 'cluster',
        binding_type                  => 'indirect',
        name_in_name_space            => 'indirectPuppetNameInNameSpace',
        string_to_bind                => undef,
        ejb_jndi_name                 => undef,
        application_server_name       => undef,
        application_node_name         => undef,
        corbaname_url                 => undef,
        federated_context             => undef,
        provider_url                  => 'example.com',
        initial_context_factory       => 'PuppetInitialContext',
        jndi_name                     => 'jndi_name',
      }
  DOC

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      # corbaPuppetTest
      [
        %r{^([^:]+)$},
        [
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:corbaPuppetTest
      [
        %r{^([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:corbaPuppetTest
      [
        %r{^([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cell:CELL_01:corbaPuppetTest
      [
        %r{^([^:]+):([^:]+):(cell):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:cluster:CELL_01:TEST_CLUSTER_01:corbaPuppetTest
      [
        %r{^([^:]+):([^:]+):(cluster):([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:cluster],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:node:CELL_01:AppNode01:corbaPuppetTest
      [
        %r{^([^:]+):([^:]+):(node):([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:server:CELL_01:AppNode01:AppServer01:corbaPuppetTest
      [
        %r{^([^:]+):([^:]+):(server):([^:]+):([^:]+):([^:]+)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:scope],
          [:cell],
          [:node_name],
          [:server],
          [:name],
        ],
      ],
    ]
  end

  ensurable do
    desc <<-EOT
    Valid values: `present`, `absent`

    Defaults to `true`.  Specifies whether this namespace binding should exist or not.
    EOT

    defaultto(:present)

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  validate do
    [:dmgr_profile, :name, :user, :node_name, :cell].each do |value|
      raise ArgumentError, "Invalid #{value} #{self[value]}" unless %r{^[-0-9A-Za-z._]+$}.match?(value)
    end

    raise ArgumentError, "Invalid scope #{self[:scope]}: Must be cell, cluster, node, or server" unless %r{^(cell|cluster|node|server)$}.match?(self[:scope])

    raise ArgumentError, 'server is required when scope is server' if self[:server].nil? && self[:scope] == 'server'
    raise ArgumentError, 'cell is a required attribute' if self[:cell].nil?
    raise ArgumentError, 'node_name is required when scope is server or node' if self[:node_name].nil? && self[:scope] =~ %r{^(server|node)$}
    raise ArgumentError, 'cluster is required when scope is cluster' if self[:cluster].nil? && self[:scope] =~ %r{^cluster$}
    raise("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end

    # general namespace_binding validatione
    raise ArgumentError, 'binding_type is invalid. Specify string, ejb, corba, or indirect' unless %r{^(string|ejb|corba|indirect)$}.match?(self[:binding_type])
    raise ArgumentError, 'name_in_name_space is required' if self[:name_in_name_space].nil?

    # string binding_type validation
    raise ArgumentError, 'string_to_bind is required when string binding_type' if self[:string_to_bind].nil? && self[:binding_type] == 'string'

    # ejb binding_type validation
    raise ArgumentError, 'ejb_jndi_name is required when ejb binding_type' if self[:ejb_jndi_name].nil? && self[:binding_type] == 'ejb'
    raise ArgumentError, 'application_server_name is required when ejb binding_type' if self[:application_server_name].nil? && self[:binding_type] == 'ejb'

    # corba binding_type validation
    raise ArgumentError, 'corbaname_url is required when corba binding_type' if self[:corbaname_url].nil? && self[:binding_type] == 'corba'
    raise ArgumentError, 'federated_context is required when corba binding_type' if self[:federated_context].nil? && self[:binding_type] == 'corba'

    # indirect binding_type validation
    raise ArgumentError, 'provider_url is required when indirect binding_type' if self[:provider_url].nil? && self[:binding_type] == 'indirect'
    raise ArgumentError, 'jndi_name is required when indirect binding_type' if self[:jndi_name].nil? && self[:binding_type] == 'indirect'
  end

  newparam(:name) do
    isnamevar
    desc 'The name of the resource'
  end

  newparam(:binding_type) do
    desc <<-EOT
    Required. The binding type of the namespace.
    EOT
  end

  newproperty(:name_in_name_space) do
    desc <<-EOT
    Required. The name of the name space relative to lookup name prefix.
    EOT
  end

  newparam(:scope) do
    isnamevar
    desc <<-EOT
    Required. The scope of namespace binding.
    Valid values: cell, node, cluster, node group or server .
    If scope is node, the cell and the node must be specified in their parameters.
    If scope is cluster, the cell and the cluster must be specified in their parameters.
    If scope is server, the cell, the node, and the server must be specified in their parameters.
    EOT
  end

  newproperty(:string_to_bind) do
    desc <<-EOT
    The stringToBind value used in the StringNameSpaceBinding.
    EOT
  end

  newproperty(:ejb_jndi_name) do
    desc <<-EOT
    The ejbJndiName value used in the EjbNameSpaceBinding.
    EOT
  end

  newproperty(:application_server_name) do
    desc <<-EOT
    The applicationServerName value used in the EjbNameSpaceBinding.
    EOT
  end

  newproperty(:application_node_name) do
    desc <<-EOT
    The applicationNodeName value used in the EjbNameSpaceBinding.
    EOT
  end

  newproperty(:corbaname_url) do
    desc <<-EOT
    The corbanameUrl value used in the CORBAObjectNameSpaceBinding.
    EOT
  end

  newproperty(:federated_context) do
    desc <<-EOT
    The federatedContext value used in the CORBAObjectNameSpaceBinding.
    EOT

    newvalues(:true, :false)

    munge do |value|
      value.to_s
    end
  end

  newproperty(:provider_url) do
    desc <<-EOT
    The providerURL value used in the IndirectLookupNameSpaceBinding.
    EOT
  end

  newproperty(:initial_context_factory) do
    desc <<-EOT
    The initialContextFactory value used in the IndirectLookupNameSpaceBinding.
    EOT
  end

  newproperty(:jndi_name) do
    desc <<-EOT
    The jndiName value used in the IndirectLookupNameSpaceBinding.
    EOT
  end

  newparam(:node_name) do
    isnamevar
    desc 'The name of the node to create this application server on'
  end

  newparam(:cluster) do
    isnamevar
    desc 'The name of the cluster to create this application server on'
  end

  newparam(:server) do
    isnamevar
    desc 'The name of the server to create this application server on'
  end

  newparam(:cell) do
    isnamevar
    desc 'The name of the cell to create this application server on'
  end

  newparam(:profile) do
    desc "The profile to run 'wsadmin' under"
  end

  newparam(:dmgr_profile) do
    isnamevar
    defaultto { @resource[:profile] }
    desc <<-EOT
    The dmgr profile that this variable should be set under.  Basically, where
    are we finding `wsadmin`

    This is synonomous with the 'profile' parameter.

    Example: dmgrProfile01
    EOT
  end

  newparam(:profile_base) do
    isnamevar
    desc <<-EOT
    The base directory that profiles are stored.
    Basically, where can we find the 'dmgr_profile' so we can run 'wsadmin'
    Example: /opt/IBM/WebSphere/AppServer/profiles"
    EOT
  end

  newparam(:user) do
    defaultto 'root'
    desc "The user to run 'wsadmin' with"
  end

  newparam(:wsadmin_user) do
    desc 'The username for wsadmin authentication'
  end

  newparam(:wsadmin_pass) do
    desc 'The password for wsadmin authentication'
  end
end
