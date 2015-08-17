# Manages WAS application servers
define websphere_application_server::profile::appserver (
  $instance_base,
  $profile_base,
  $cell,
  $node_name,
  $profile_name      = $title,
  $user              = $::websphere_application_server::user,
  $group             = $::websphere_application_server::group,
  $dmgr_host         = undef,
  $dmgr_port         = undef,
  $template_path     = undef,
  $options           = undef,
  $manage_federation = true,
  $manage_service    = true,
  $manage_sdk        = false,
  $sdk_name          = undef,
  $wsadmin_user      = undef,
  $wsadmin_pass      = undef,
) {

  validate_absolute_path($instance_base)
  validate_absolute_path($profile_base)
  validate_string($cell)
  validate_string($node_name)
  validate_string($profile_name)
  validate_string($user)
  validate_string($group)
  validate_string($dmgr_host)
  validate_string($dmgr_host)
  validate_bool($manage_federation)
  validate_bool($manage_service)
  validate_bool($manage_sdk)

  ## Template path. Figure out a sane default if not explicitly specified.
  if ! $template_path {
    $_template_path = "${instance_base}/profileTemplates/app"
  } else {
    $_template_path = $template_path
  }
  validate_absolute_path($_template_path)

  if $manage_sdk and !$sdk_name {
    fail('sdk_name is required when manage_sdk is true. E.g. 1.71_64')
  }

  if $manage_sdk and !$manage_federation {
    fail('manage_federation must be true when manage_sdk is true')
  }

  ## Build our installation options if none are profided. These are mostly
  ## similar, but we do add extra to the 'app' profile type. Hackish.
  if ! $options {
    $_options = "-create -profileName ${profile_name} -profilePath ${profile_base}/${profile_name} -templatePath ${_template_path} -nodeName ${node_name} -hostName ${::fqdn} -federateLater true -cellName standalone"
  } else {
    $_options = $options
  }
  validate_string($_options)

  ## Create the profile
  ## manageprofiles.sh will exit 0 even if it fails. Let's at least test that
  ## the profile directory exists before calling it successful.
  exec { "was_profile_app_${title}":
    command => "${instance_base}/bin/manageprofiles.sh ${_options} && test -d ${profile_base}/${profile_name}",
    creates => "${profile_base}/${profile_name}",
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    user    => $user,
    timeout => 900,
  }

  # Ensure ownership of profile directory is correct
  websphere_application_server::ownership { $title:
    user    => $user,
    group   => $group,
    path    => "${profile_base}/${profile_name}",
    require => Exec["was_profile_app_${title}"],
  }

  $_dmgr_host = downcase($dmgr_host)
  $_cell = downcase($cell)

  ## Collect the federation resource
  File <<| title == "/etc/dmgr_${_dmgr_host}_${_cell}" |>> {
    path   => "${profile_base}/${profile_name}/dmgr_${_dmgr_host}_${_cell}.yaml",
    before => Websphere_federate["${title}_${dmgr_host}_${cell}"],
  }

  if $manage_federation {
    websphere_federate { "${title}_${dmgr_host}_${cell}":
      ensure       => present,
      node         => $node_name,
      cell         => $cell,
      profile_base => $profile_base,
      profile      => $profile_name,
      dmgr_host    => $dmgr_host,
      user         => $user,
      username     => $wsadmin_user,
      password     => $wsadmin_pass,
      before       => Websphere_application_server::Profile::Service[$title],
    }

    ## Modifying SDK requires federation
    if $manage_sdk {
      websphere_sdk { "${title}_${sdk_name}":
        profile             => $profile_name,
        server              => 'all',
        sdkname             => $sdk_name,
        instance_base       => $instance_base,
        new_profile_default => $sdk_name,
        command_default     => $sdk_name,
        user                => $user,
        username            => $wsadmin_user,
        password            => $wsadmin_pass,
        require             => Websphere_federate["${title}_${dmgr_host}_${cell}"],
        notify              => Websphere_application_server::Profile::Service[$title],
      }
    }
  }

  if $manage_service {
    websphere_application_server::profile::service { $title:
      type         => 'app',
      profile_base => $profile_base,
      user         => $user,
      wsadmin_user => $wsadmin_user,
      wsadmin_pass => $wsadmin_pass,
      require      => Exec["was_profile_app_${title}"],
      subscribe    => Websphere_application_server::Ownership[$title],
    }
  }

}
