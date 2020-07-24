require 'pathname'

Puppet::Type.newtype(:websphere_security_custom_property) do
  @doc = <<-DOC
    @summary This manages a WebSphere Global Security Custom Property'
    @example
      websphere_security_custom_property { 'com.ibm.websphere.tls.disabledAlgorithms':
        ensure                        => 'present',
        dmgr_profile                  => 'PROFILE_DMGR_01',
        profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
        user                          => 'webadmin',
        cell                          => 'CELL_01',
        node_name                     => 'DMGR_01',
        property_value                => 'SSLv3,TLSv1,RC4,DH keySize < 768,MD5withRSA',
      }
  DOC

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      # PuppetTest
      [
        %r{^([^:]+)$},
        [
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PuppetTest
      [
        %r{^(.*):(.*)$},
        [
          [:profile_base],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:PuppetTest
      [
        %r{^(.*):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:CELL_01:PuppetTest
      [
        %r{^(.*):(.*):(.*):(.*)$},
        [
          [:profile_base],
          [:dmgr_profile],
          [:cell],
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
    [:dmgr_profile, :name, :user, :node, :cell].each do |value|
      raise ArgumentError, "Invalid #{value} #{self[value]}" unless value =~ %r{^[-0-9A-Za-z._]+$}
    end

    raise("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end
  end

  newparam(:name) do
    isnamevar
    desc 'The name of the resource'
  end

  newproperty(:property_value) do
    desc <<-EOT
    The value of the custom property.
    EOT
  end

  newproperty(:description) do
    desc <<-EOT
    The description of the security custom property.
    EOT
  end

  newparam(:node) do
    desc 'The name of the node to create this application server on'
  end

  newparam(:cluster) do
    desc 'The name of the cluster to create this application server on'
  end

  newparam(:server) do
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
