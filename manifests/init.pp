# websphere_application_server
#
# @summary
#   base class for the module that sets up dirs and users
#
# @param base_dir
#   base directory where all IBM software will be installed
# @param user
#   The user name that owns and executes the WebSphere installation. Valid options: a string containing a valid user name. Default: `webadmin`.
# @param group
#   The permissions group for the WebSphere installation. Valid options: a string containing a valid group name. Default: `webadmins`.
# @param user_home
#   Specifies the home directory for the specified user if `manage_user` is `true`. Valid options: an absolute path to a directory. Default: `/opt/IBM`.
# @param manage_user
#   Specifies whether the class manages the user specified in `user`. Valid options: boolean. Default: true.
# @param manage_group
#   Specifies whether the class manages the group specified in `group`. Valid options: boolean. Default: true.
class websphere_application_server (
  $base_dir          = '/opt/IBM',
  $user              = 'websphere',
  $group             = 'websphere',
  $user_home         = '/opt/IBM',
  $manage_user       = true,
  $manage_group      = true,
) {

  validate_string($user, $group)
  validate_absolute_path($base_dir, $user_home)
  validate_bool($manage_user, $manage_group)

  if $manage_user {
    user { $user:
      ensure     => 'present',
      home       => $user_home,
      gid        => $group,
    }
  }

  if $manage_group {
    group { $group:
      ensure => 'present',
    }
  }

  # Seems some of these tools expect /opt/IBM and some data directories there,
  # even when the installation directory is different.  Manage these for good
  # measure.
  if $base_dir == '/opt/IBM' {
    $java_prefs = [
      '/opt/IBM',
      '/opt/IBM/.java',
      '/opt/IBM/.java/systemPrefs',
      '/opt/IBM/.java/userPrefs',
      '/opt/IBM/workspace',
    ]
  } else {
    $java_prefs = [
      '/opt/IBM',
      "${base_dir}/.java",
      "${base_dir}/.java/systemPrefs",
      "${base_dir}/.java/userPrefs",
      "${base_dir}/workspace",
      '/opt/IBM/.java',
      '/opt/IBM/.java/systemPrefs',
      '/opt/IBM/.java/userPrefs',
      '/opt/IBM/workspace',
    ]
  }
  file { $java_prefs:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }

  ensure_resource('file', ['/etc/puppetlabs/facter', '/etc/puppetlabs/facter/facts.d'], { 'ensure' => 'directory' })

  ## concat is used to populate a file for facter
  concat { '/etc/puppetlabs/facter/facts.d/websphere.yaml':
    ensure => 'present',
  }
  concat::fragment { 'websphere_facts_header':
    target  => '/etc/puppetlabs/facter/facts.d/websphere.yaml',
    order   => '01',
    content => "---\nwebsphere_base_dir: ${base_dir}\n",
  }

}
