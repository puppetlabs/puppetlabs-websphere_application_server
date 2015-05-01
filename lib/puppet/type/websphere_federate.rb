require 'pathname'

Puppet::Type.newtype(:websphere_federate) do

  @doc = <<-EOT
  Manages the federation of WebSphere application servers with a cell.

  By default, this resource expects that a data file will be available in
  Puppet's `$vardir` containing information about the DMGR cell to federate
  with.

  By default, this module's `websphere::profile::dmgr` defined type will
  _export_ a file resource containing this information.  The application
  servers that have declared `websphere::profile::appserver` will _collect_
  that exported resource and place it under
  `${vardir}/dmgr_${dmgr_host}_${cell}.yaml` For example:
  `/var/opt/lib/pe-puppet/dmgr_dmgr.example.com_cell01.yaml`  This is all
  automatic behind the scenes.

  To federate, the application server needs to know the DMGR SOAP port, which
  is included in this exported/collected file.  Optionally, you may provide it
  as a parameter value if you're using this resource type directly.

  Essentially, the provider for this resource type executes `addNode.sh` to do
  the federation.
  EOT

  ensurable

  newparam(:cell) do
    desc "Required. The name of the DMGR cell to federate with"
  end

  newparam(:dmgr_host) do
    desc "Required. The dmgr host to federate with"
  end

  newparam(:node) do
    desc "Required. The node name to federate"
  end

  newparam(:profile) do
    isnamevar
    desc "The profile to federate"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid profile #{value}")
      end
    end
  end

  newparam(:profile_base) do
    desc "The base directory that profiles are stored.
      Example: /opt/IBM/WebSphere/AppServer/profiles"

    validate do |value|
      fail("Invalid profile_base #{value}") unless Pathname.new(value).absolute?
    end
  end

  newparam(:soap_port) do
    desc "The soap port to connect to for federation"
  end

  newparam(:username) do
    desc "The username for federation (for addNode.sh)"
  end

  newparam(:password) do
    desc "The password for federation (for addNode.sh)"
  end

  newparam(:options) do
    desc "Custom options to pass to addNode or removeNode.sh"
  end

  newparam(:user) do
    defaultto 'root'
    desc "User to run the federation commands with"
  end

  newparam(:wsadmin_user) do
    desc "Specifies the username for using 'wsadmin'"
  end

  newparam(:wsadmin_pass) do
    desc "Specifies the password for using 'wsadmin'"
  end

  autorequire(:file) do
    "dmgr_" + self[:dmgr_host].to_s.downcase + "_" + self[:cell].to_s.downcase
  end

  autorequire(:user) do
    self[:user] unless self[:user].to_s.nil?
  end

end
