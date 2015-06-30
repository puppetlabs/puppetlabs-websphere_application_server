##
## Define to manage the installation of IBM HTTPServer (IHS) instances
## 2015-01-13/jbeard: Does what it's supposed to.
## TODO: The service resource isn't idempotent because IBM writes shitty
## software.  Their 'adminctl' script hardcodes a port number in it
## for server status and uses lynx.  We'll probably end up checking the
## damn PID file ourselves.
##
define websphere_application_server::ihs::instance (
  $base_dir                  = $::websphere_application_server::base_dir,
  $target                    = undef,
  $package                   = undef,
  $version                   = undef,
  $repository                = undef,
  $response_file             = undef,
  $install_options           = undef,
  $imcl_path                 = undef,
  $manage_user               = true,
  $manage_group              = true,
  $user                      = $::websphere_application_server::user,
  $group                     = $::websphere_application_server::group,
  $user_home                 = $::websphere_application_server::user_home,
  $log_dir                   = undef,
  $webroot                   = undef,
  $admin_listen_port         = '8008',
  $adminconf_template        = undef,
  $replace_config            = true,
  $server_name               = $::fqdn,
  $manage_htpasswd           = true,
  $admin_username            = 'httpadmin',
  $admin_password            = 'password',
) {

  File {
    owner => $user,
    group => $group,
  }

  if ! $target {
    $_target = "${base_dir}/${title}"
  } else {
    $_target = $target
  }
  validate_absolute_path($_target)

  if ! $log_dir {
    $_log_dir = "${_target}/logs"
  } else {
    $_log_dir = $log_dir
  }
  validate_absolute_path($_log_dir)

  if ! $webroot {
    $_webroot = '/opt/web'
  } else {
    $_webroot = $webroot
  }
  validate_absolute_path($_webroot)

  if ! $adminconf_template {
    $_adminconf_template = "${module_name}/ihs/admin.conf.erb"
  } else {
    $_adminconf_template = $adminconf_template
  }

  # Ensure any non-admin user and group we'll use are present.
  # IBM's "expected layout" wants this user's home to be where IM is installed.
  validate_bool($manage_user)
  if $manage_user {
    user { $user:
      ensure => 'present',
      home   => $user_home,
      gid    => $group,
    }
  }
  validate_bool($manage_group)
  if $manage_group {
    group { $group:
      ensure => 'present',
    }
  }

  ibm_pkg { "IHS ${title}":
    ensure           => 'present',
    package          => $package,
    version          => $version,
    target           => $_target,
    response         => $response_file,
    options          => $install_options,
    repository       => $repository,
    manage_ownership => true,
    imcl_path        => $imcl_path,
    package_owner    => $user,
    package_group    => $group,
  }

  file { $_webroot:
    ensure  => 'directory',
    require => Ibm_pkg["IHS ${title}"],
  }

  file { $_log_dir:
    ensure  => 'directory',
    require => Ibm_pkg["IHS ${title}"],
  }

  ## Config file for the admin HTTP instance.
  file { "ihs_adminconf_${title}":
    ensure  => 'file',
    path    => "${_target}/conf/admin.conf",
    content => template($_adminconf_template),
    mode    => '0775',
    replace => $replace_config,
    require => Ibm_pkg["IHS ${title}"],
  }

  # Total hack here. We want to configure an admin password during the run
  # so that things can "just work". This is a simple htpasswd auth.
  # Without having this setup, the DMGR won't be able to talk to the IHS
  # server.
  # Unfortunately, htpasswd doesn't offer a "verify" function. We have a small
  # shell script to do this using openssl.
  # It's in a template to keep the long stuff out of the DSL here. Eventually,
  # a cleaner way of doing this should be looked implemented.
  validate_bool($manage_htpasswd)
  if $manage_htpasswd {
    validate_string($admin_username)
    validate_string($admin_password)
    $htpasswd_verify = template("${module_name}/ihs/htpasswd.erb")
    exec { "htpasswd for admin ${title}":
      command => "${_target}/bin/htpasswd -b -c ${_target}/conf/admin.passwd ${admin_username} ${admin_password}",
      unless  => "/bin/sh -c '${htpasswd_verify}'",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      user    => $user,
      require => Ibm_pkg["IHS ${title}"],
    }
  }

  # IHS Admin service
  # Requires 'lynx' to check the status and hardcodes a port.
  # For now, let's look at the process table for a matching process.
  # The 'src' service provider for AIX yields unexpected results when providing
  # custom commands for start/stop/restart/status.  For now, we'll just use
  # 'base' as the provider until an upstream answer is retrieved.
  service { "ihs_admin_${title}":
    ensure    => 'running',
    start     => "su - ${user} -c '${_target}/bin/adminctl start'",
    stop      => "su - ${user} -c '${_target}/bin/adminctl stop'",
    restart   => "su - ${user} -c '${_target}/bin/adminctl restart'",
    #status   => "su - ${user} -c '${_target}/bin/adminctl status'",
    pattern   => "${target}/bin/httpd -f ${target}/conf/admin.conf",
    hasstatus => false,
    provider  => 'base',
    subscribe => File["ihs_adminconf_${title}"],
  }

}
