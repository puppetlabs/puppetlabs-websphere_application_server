require 'pathname'

Puppet::Type.newtype(:websphere_sdk) do

  @doc = "This manages WebSphere SDK/JDK versions"

  newparam(:server) do
    desc <<-EOT
      The server in the scope for this variable.
      This can be a specific server or 'all' to affect all servers

      'all' corresponds to the 'managesdk.sh' option '-enableServers'
    EOT

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid server #{value}"
      end
    end
  end

  newparam(:node) do

  end

  newparam(:profile) do
    desc <<-EOT
      The profile to modify.
      Specify 'all' for all profiles. 'all' corresponds to the 'managesdk.sh'
      option '-enableProfileAll'

      A specific profile name can also be provided. Example: PROFILE_APP_001.
      This corresponds to 'managesdk.sh' options -enableProfile -profileName
    EOT

    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid profile #{value}"
      end
    end
  end

  newparam(:name) do
    isnamevar
    desc <<-EOT
      The name of the resource. This is only used for Puppet to identify
      the resource and has no influence over the commands used to make
      modifications or query SDK versions.
    EOT
  end

  newproperty(:sdkname) do
    desc "The name of the SDK to modify. Example: 1.7.1_64"

  end

  newparam(:instance_base) do
    desc <<-EOT
      The base directory that WebSphere is installed.
      Example: `/opt/IBM/WebSphere/AppServer/`
    EOT

    validate do |value|
      unless Pathname.new(value).absolute?
        raise ArgumentError, "Invalid instance_base #{value}"
      end
    end
  end

  newproperty(:command_default) do
    desc <<-EOT
      Manages the SDK name that script commands in the
      app_server_root/bin, app_client_root/bin, or plugins_root/bin directory
      are enabled to use when no profile is specified by the command and when
      no profile is defaulted by the command.
    EOT
  end

  newproperty(:new_profile_default) do
    desc <<-EOT
      Manages the SDK name that is currently configured for all profiles
      that are created with the manageprofiles command. The -sdkname parameter
      specifies the default SDK name to use. The sdkName value must be an SDK
      name that is enabled for the product installation.
    EOT
  end

  newparam(:user) do
    defaultto 'root'
    desc "The user to run 'wsadmin' with"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        raise ArgumentError, "Invalid user #{value}"
      end
    end
  end

  newparam(:username) do
    desc "The username for 'managesdk.sh' authentication"
  end

  newparam(:password) do
    desc "The password for 'managesdk.sh' authentication"
  end
end
