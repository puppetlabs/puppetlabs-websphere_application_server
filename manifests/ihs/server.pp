# Manage web server (http) instances on IHS
define websphere_application_server::ihs::server (
  $target,
  $httpd_config            = undef,
  $user                    = $::websphere_application_server::user,
  $group                   = $::websphere_application_server::group,
  $docroot                 = undef,
  $instance                = $title,
  $httpd_config_template   = "${module_name}/ihs/httpd.conf.erb",
  $timeout                 = '300',
  $max_keep_alive_requests = '100',
  $keep_alive              = 'On',
  $keep_alive_timeout      = '10',
  $thread_limit            = '25',
  $server_limit            = '64',
  $start_servers           = '1',
  $max_clients             = '600',
  $min_spare_threads       = '25',
  $max_spare_threads       = '75',
  $threads_per_child       = '25',
  $max_requests_per_child  = '25',
  $limit_request_field_size = '12392',
  $listen_address          = $::fqdn,
  $listen_port             = '10080',
  $server_admin_email      = 'user@example.com',
  $server_name             = $::fqdn,
  $server_listen_port      = '80',
  $pid_file                = "${title}.pid",
  $replace_config          = true,
  $directory_index         = 'index.html index.html.var',
  $log_dir                 = undef,
  $access_log              = 'access_log',
  $error_log               = 'error_log',
  $export_node             = true,
  $export_server           = true,
  $node                    = $::fqdn,
  $node_hostname           = $::fqdn,
  $node_os                 = undef,
  $cell                    = undef,
  $admin_username          = 'httpadmin',
  $admin_password          = 'password',
  $plugin_base             = '/opt/IBM/Plugins',
  $propagate_keyring       = true,
  $dmgr_host               = undef,
) {

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  File {
    owner  => $user,
    group  => $group,
  }

  if !$docroot {
    $_docroot = "${target}/htdocs"
  } else {
    $_docroot = $docroot
  }

  if !$httpd_config {
    $_httpd_config = "${target}/conf/httpd_${title}.conf"
  } else {
    $_httpd_config = $httpd_config
  }

  if !$log_dir {
    $_log_dir = "${target}/logs"
  } else {
    $_log_dir = $log_dir
  }

  file { "${title} ${_docroot}":
    ensure => 'directory',
    path   => $_docroot,
  }

  file { "${plugin_base}/config/${instance}":
    ensure => 'directory',
  }

  ## Use exec to create the log_dir.  It might be several levels deep.  In that
  ## case, a regular 'file' resource would be tricky.
  exec { "${title}_log_dir":
    command => "mkdir -p ${_log_dir}",
    creates => $_log_dir,
  }

  file { "${title}_httpd_config":
    ensure  => 'file',
    path    => $_httpd_config,
    content => template($httpd_config_template),
    replace => $replace_config,
  }

  service { "${title}_httpd":
    ensure    => 'running',
    start     => "su - ${user} -c \"${target}/bin/apachectl -k start -f '${_httpd_config}'\"",
    stop      => "su - ${user} -c \"${target}/bin/apachectl -k stop -f '${_httpd_config}'\"",
    restart   => "su - ${user} -c \"${target}/bin/apachectl -k restart -f '${_httpd_config}'\"",
    hasstatus => false,
    pattern   => "${target}/bin/httpd.*-f ${_httpd_config}",
    provider  => 'base',
    subscribe => File["${title}_httpd_config"],
  }

  # Exporting for a DMGR to collect.
  if $export_node {

    if $node_os {
      $_node_os = $node_os
    } else {
      $_node_os = downcase($::kernel)
    }

    validate_re($_node_os, '(aix|linux)', "Invalid node_os: #{_node_os}. Must be 'aix' or 'linux'")

    if !$cell or !$node or !$dmgr_host {
      fail('cell, node, and dmgr_host is required when export_node is true')
    }

    validate_bool($propagate_keyring)


    @@websphere_node { "ihs_${title}_${node_hostname}":
      node      => $node,
      os        => $_node_os,
      hostname  => $node_hostname,
      cell      => $cell,
      dmgr_host => $dmgr_host,
    }

    if $export_server {
      @@websphere_web_server { "web_${title}_${node_hostname}":
        name              => $title,
        node              => $node,
        cell              => $cell,
        admin_user        => $admin_username,
        admin_pass        => $admin_password,
        plugin_base       => $plugin_base,
        install_root      => $target,
        config_file       => $_httpd_config,
        access_log        => $access_log,
        error_log         => $error_log,
        web_port          => $listen_port,
        propagate_keyring => $propagate_keyring,
        dmgr_host         => $dmgr_host,
        require           => Websphere_node["ihs_${title}_${node_hostname}"],
      }
    }

  }

}
