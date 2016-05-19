require 'installer_constants'

# Download a compressed file from http repository and uncompress it
#
# ==== Attributes
#
# * +hosts+ - The target host where the compressed file is downloaded and uncompressed.
# * +urllink+ - The http link to where the compressed file is located .
# * +compressed_file+ - The name of the compressed file.
# * +uncompress_to+ - The target directory on the host where all files/directories are uncompressed to.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# +Minitest::Assertion+ - Failed to download and/or uncompress.
#
# ==== Examples
#
# download_and_uncompress('agent'
#                  'http://int-resources.ops.puppetlabs.net/QA_resources/ibm_websphere/',
#                  'was.repo.8550.ihs.ilan_part1.zip',
#                  '"/ibminstallers/ibm/ndtrial"',)
def download_and_uncompress(host, installer_url, cfilename, dest_directory, directory_path)

  #ERB Template
  # installer_url = urllink
  # cfilename = compressed_file
  # dest_directory = uncompress_to
  #directory_path = dest_directory
  if cfilename.include? "zip"
    compress_type = 'zip'
  elsif cfilename.include? "tar.gz"
    compress_type = 'tar.gz'
  else
    fail_test "only zip or tar.gz are is valid compressed file "
  end

  local_files_root_path = ENV['FILES'] || "tests/files"
  manifest_template     = File.join(local_files_root_path, 'download_uncompress_manifest.erb')
  manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

  on(host, puppet('apply'), :stdin => manifest_erb, :exceptable_exit_codes => [0,2]) do |result|
    assert_no_match(/Error/, result.output, 'Failed to download and/or uncompress')
  end
end

# Verify if IBM Installation Manager is installed
#
# ==== Attributes
#
# * +installed_directory+ - The directory where IBM Installation Manager is installed
# By default, the directory is /opt/IBM. This can be configured by 'target' attribute
# in 'ibm_installation_manager' class
# Since IM a UI tool, the verification is only checking if the launcher, license file,
# and the version file are in the right locations.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# verify_im_installed?(custom_location)
def verify_im_installed?(installed_directory)
  step "Verify IBM Installation Manager is installed into directory: #{installed_directory}"
  step 'Verify 1/3: IBM Installation Manager Launcher'
  if agent.file_exist?("#{installed_directory}/eclipse/launcher") == nil
    fail_test "Launcher has not been found in: #{installed_directory}/eclipse"
  end

  step 'Verify 2/3: IBM Installation Manager License File'
  if agent.file_exist?("#{installed_directory}/license/es/license.txt") == nil
    fail_test "License file has not been found in: #{installed_directory}/license"
  end

  step 'Verify 3/3: IBM Installation Manager Version'
  if agent.file_exist?("#{installed_directory}/properties/version/IBM_Installation_Manager.*") == nil
    fail_test "Version has not been found in: #{installed_directory}/properties/version"
  end
end

# Verify if files/directories are created:
#
# ==== Attributes
#
# * +files+ - a file/directory or an array of files/directories that need to be verified
# if they are successfully created
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# verify_file_exist?('/opt/log/websphere')
#
def verify_file_exist?(files)
  error_message = "File/Directory does not exist: #{files}"
  if files.kind_of?(Array)
    files.each do |file|
      if agent.file_exist?(file) == false
        fail_test error_message
      end
    end
  elsif files.kind_of(String)
    if agent.file_exist?(files) == false
      fail_test error_message
    end
  else
    raise Exception
  end
end

# remove websphere application server:
#
# ==== Attributes
#
# * +class_name+ - The websphere_application_server class that needs to
# * be removed
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# remove_websphere('websphere_application_server')
#
def remove_websphere(class_name)
pp = <<-MANIFEST
  class { "#{class_name}":
    ensure => absent,
  }
MANIFEST
  create_remote_file(agent, "/root/remove_websphere.pp", pp)
  on(agent, "/opt/puppetlabs/puppet/bin/puppet apply /root/remove_websphere.pp")
end

# Verify if websphere instance is created:
#
# ==== Attributes
#
# * +host+ - a PE agent where websphere instance is created
#
# * +ws_instance_name+ - name of the created websphere instance
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail messages
#
# ==== Examples
#
# verify_websphere_created?(agent, 'WebSphere85')
#
def verify_websphere_created?(host, ws_instance_name)
  #getting command line:
  if (host['platform'] =~ /aix/)
    command = "/usr/bin/ps -elf | grep -i #{ws_instance_name}"
  elsif (host['platform'] =~ /linux/)
    command = "ps -ef | grep -i #{ws_instance_name}"
  end

  on(host, command, :acceptable_exit_codes => 0)
end

# remove websphere instance:
#
# ==== Attributes
#
# * +instance_name+ - The websphere instance that needs to be removed
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# remove_websphere(agent, 'websphere_application_server', '/opt/IBM')
#
def remove_websphere_instance(host, instance_name, remove_directories)
  pp = <<-MANIFEST
  websphere_application_server::instance { '#{instance_name}':
    ensure => absent,
  MANIFEST
  create_remote_file(host, "/tmp/remove_websphere_instance.pp", pp)
  on(host, "/opt/puppetlabs/puppet/bin/puppet apply /tmp/remove_websphere_instance.pp", :acceptable_exit_codes => [0,2])

  if remove_directories
    on(agent, "rm -rf #{remove_directories}", :acceptable_exit_codes => [0,127])
  end
end

# Verify if the correct version is installed:
#
# ==== Attributes
#
# * +host+ - a PE agent where websphere instance is created
#
# * +command+ - the command executed on the host
#
# * +verify_str+ - a string that needs to be verified with WebSphere
# for example, a string of WebSphere version that needs to be ensured
# it is successfully installed on the host.
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail messages
#
# ==== Examples
#
# verify_websphere(agent, "/opt/ibm/WebSphere85/AppServer/bin/versionInfo.sh", "8.5.5004.20141119_1746")
#
def verify_websphere(host, command, verify_str)
  #getting full command line:
  full_command = "#{command} | grep #{verify_str}"
  on(host, full_command)
end

# Get a fresh VM from vmPooler for WebSphere node
#
# ==== Attributes
#
# * +str+ - a vPooler VM template name
#
# ==== Returns
#
# +hostname of the acquired vPooler VM+
#
# ==== Raises
#
# fail messages
#
# ==== Examples
#
# get_fresh_node('centos-6-x86_64')
#
def get_fresh_node(str)
  system("curl -d --url vcloud.delivery.puppetlabs.net/vm/#{str} > create_node.txt")
  system("cat create_node.txt")
  File.readlines('create_node.txt').each do |line|
    if line =~/hostname/
      hostname = line.scan(/(:\s+")(.*)(")/)[0][1]
      return hostname
    end
  end
end

# return node back to the pooler:
#
# ==== Attributes
#
# * +node_name+ - The hostname of the VM that needs to return back to vmPooler
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail_test messages
#
# ==== Examples
#
# return_node_to_pooler('lh55s4v0mu1ufhb')
#
def return_node_to_pooler(node_name)
  system("curl -X DELETE vcloud.delivery.puppetlabs.net/vm/#{node_name}")
end

# Verify if a cluster or a cluster member exists:
#
# ==== Attributes
#
# * +host+ - a PE agent where websphere instance is created
#
# * +cluster_name+ - the string name of verified cluster
#
# * +cluster_member+ - the string of verified cluster member
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail messages
#
# ==== Examples
#
# Verify if a cluster exists
# verify_cluster(agent, 'MyCluster01')
#
# Verify if a cluster member exists
# verify_cluster(agent, 'MyCluster01', 'AppServer01')
def verify_cluster(host, cluster_name, cluster_member=nil)
  instance_base = WebSphereConstants.instance_base
  path          = "#{instance_base}/scriptLibraries/server/V70/AdminClusterManagement"

  if cluster_member #verify if a cluster member exists
    command = "#{path}.listClusterMembers(\"#{cluster_name}\") | grep \"#{cluster_member}\""
  else #verify if a cluster exists
    command = "#{path}.checkIfClusterExists(\"#{cluster_name}\")"
  end
  on(host, command)
end

# Utilize the WebSphere wsadmin tool with jython:
#
# ==== Attributes
#
# * +host+ - a PE agent where websphere instance is created
#
# * +wsadmin_object+ - the wsadmin object for administrative operations, there are 5 wsadmin objects:
#                      AdminControl, AdminConfig, AdminApp, AdminTask, and Help
#
# * +verified_str+ - the string that need to be verified if it exists in the output of an wsadmin command/script
#
# ==== Returns
#
# +nil+
#
# ==== Raises
#
# fail messages
#
# ==== Examples
#
# Verify if a node scoped variable exists
# wsadmin_tool("AdminTask.showVariables", "NODE_LOG_ROOT")
def wsadmin_tool(host, wsadmin_object, verified_str)
  profile_base  = WebSphereConstants.profile_base
  path          = "#{profile_base}/bin"
  command       = "#{path}/wsadmin.sh -lang jython -c '#{wsadmin_object}' | grep \"#{verified_str}\""

  on(host, command)
end
