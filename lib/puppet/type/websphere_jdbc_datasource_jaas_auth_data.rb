require 'pathname'

Puppet::Type.newtype(:websphere_jdbc_datasource_jaas_auth_data) do
  @doc = <<-DOC
    @summary This manages WebSphere JDBC JAAS Auth Data. Also known as auth aliases.
    @example
      websphere_jdbc_datasource_jaas_auth_data { 'Puppet Test':
        ensure                        => 'present',
        dmgr_profile                  => 'PROFILE_DMGR_01',
        profile_base                  => '/opt/IBM/WebSphere/AppServer/profiles',
        user                          => 'webadmin',
        cell                          => 'CELL_01',
        node_name                     => 'AppNode01',
        user_id                       => 'User_test',
        password                      => 'password123',
        description                   => 'Created by Puppet',
      }
  DOC

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      # AuthAliasName
      [
        %r{^([^:]+)$},
        [
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:AuthAliasName
      [
        %r{^(.*):(.*)$},
        [
          [:profile_base],
          [:name],
        ],
      ],
      # /opt/IBM/WebSphere/AppServer/profiles:PROFILE_DMGR_01:CELL_01:AuthAliasName
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

    Defaults to `true`. Specifies whether this JAAS auth data should exist or not.
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

    raise ArgumentError, 'cell is a required attribute' if self[:cell].nil?
    raise("Invalid profile_base #{self[:profile_base]}") unless Pathname.new(self[:profile_base]).absolute?

    if self[:profile].nil?
      raise ArgumentError, 'profile is required' unless self[:dmgr_profile]
      self[:profile] = self[:dmgr_profile]
    end
  end

  newproperty(:user_id) do
    desc <<-EOT
    The user id of the auth alias
    EOT
  end

  newproperty(:password) do
    desc <<-EOT
    The password of the auth alias.
    EOT
  end

  newproperty(:description) do
    desc <<-EOT
    The description of the auth alias.
    EOT
  end

  newparam(:name) do
    isnamevar
    desc 'The name of the resource'
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

    Example: dmgrProfile01"
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
