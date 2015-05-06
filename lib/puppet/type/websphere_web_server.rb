require 'pathname'

Puppet::Type.newtype(:websphere_web_server) do

  @doc = <<-EOT
    Manages WebSphere web servers in a cell.
  EOT

  ensurable

  newparam(:dmgr_profile) do
    desc <<-EOT
      The dmgr profile that this cluster belongs to.
      Example: dmgrProfile01
    EOT

    validate do |value|
      unless value =~ /^[-0-9A-Za-z_.]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:cell) do
    desc <<-EOT
    The cell that this web server should belong to.  This is used for adding
    IHS instances to a WebSphere cell.

    This is needed for a DMGR to know what web servers belong to it.
    EOT
  end

  newparam(:name) do
    isnamevar
    desc "The name of the Web Server"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z_.]+$/
        fail("Invalid name #{value}")
      end
    end
  end

  newparam(:node) do
    desc "The name of the node to create this web server on"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid dmgr_profile #{value}")
      end
    end
  end

  newparam(:propagate_keyring) do
    desc "Propagate the plugin keyring from the DMGR to the server when the
    server is created."
    defaultto false
  end

  newparam(:config_file) do
    desc "The full path to the HTTP config file"
  end

  newparam(:template) do
    desc "The template to use for creating the web server.
    Defaults to IHS
    "
    defaultto 'IHS'
  end

  ## This could eventually be a property
  newparam(:access_log) do
    desc "The path for the access log"
  end

  ## This could eventually be a property
  newparam(:error_log) do
    desc "The path for the error log"
  end

  ## This could eventually be a property
  newparam(:web_port) do
    desc "The port for the HTTP server. Defaults to '80'"
    defaultto '80'
  end

  newparam(:install_root) do
    defaultto '/opt/IBM/HTTPServer'
    desc "The install root of the HTTP server location.
    For example: /opt/IBM/HTTPServer
    "
  end

  newparam(:protocol) do
    desc "The protocol for the HTTP server. Defaults to 'HTTP'"
    defaultto 'HTTP'
  end

  newparam(:plugin_base) do
    desc "The full path to the plugin base directory on the HTTP server
    Example: /opt/IBM/HTTPServer/Plugins
    "
  end

  newparam(:web_app_mapping) do
    desc "Application mapping to the Web server. 'ALL' or 'NONE'.
    Defaults to 'NONE'
    "
    defaultto 'NONE'
  end

  newparam(:admin_port) do
    desc "Administration Server Port. Defaults to '8008'"
    defaultto '8008'
  end

  newparam(:admin_user) do
    desc "IBM Administration Server username. Required."
  end

  newparam(:admin_pass) do
    desc "IBM Administration Server password. Required."
  end

  newparam(:admin_protocol) do
    desc "Protocol for administration. 'HTTP' or 'HTTPS'.
    Defaults to 'HTTP'
    "
    defaultto 'HTTP'
  end

  newparam(:profile_base) do
    desc "The base directory that profiles are stored.
      Example: /opt/IBM/WebSphere/AppServer/profiles"

    validate do |value|
      fail("Invalid profile_base #{value}") unless Pathname.new(value).absolute?
    end
  end

  newparam(:user) do
    defaultto 'root'
    desc "The user to run 'wsadmin' with"
    validate do |value|
      unless value =~ /^[-0-9A-Za-z._]+$/
        fail("Invalid user #{value}")
      end
    end
  end

  newparam(:dmgr_host) do
    desc <<-EOT
      The DMGR host to add this web server to.

      This is required if you're exporting the web server for a DMGR to
      collect.  Otherwise, it's optional.
    EOT
  end

  newparam(:wsadmin_user) do
    desc "The username for wsadmin authentication"
  end

  newparam(:wsadmin_pass) do
    desc "The password for wsadmin authentication"
  end
end
