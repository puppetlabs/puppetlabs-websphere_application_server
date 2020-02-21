# @summary
#   Manages WAS application servers.
#
# @example Create a basic AppServer profile
#   websphere_application_server::profile::appserver { 'PROFILE_APP_001':
#     instance_base  => '/opt/IBM/WebSphere/AppServer',
#     profile_base   => '/opt/IBM/WebSphere/AppServer/profiles',
#     cell           => 'CELL_01',
#     template_path  => '/opt/IBM/WebSphere/AppServer/profileTemplates/managed',
#     node_name      => 'appNode01',
#   }
#
# @param instance_base
#   Required. The full path to the installation of WebSphere that this profile should be created under. The IBM default is '/opt/IBM/WebSphere/AppServer'.
# @param profile_base
#   Required. The full path to the base directory of profiles. The IBM default is '/opt/IBM/WebSphere/AppServer/profiles'.
# @param cell
#   Required. The cell name to create. For example: 'CELL_01'.
# @param node_name
#   Required. The name for this "node". For example: 'appNode01'.
# @param profile_name
#   The name of the profile. The directory that gets created will be named this. Example: 'PROFILE_APP_01' or 'appProfile01'. Recommended to keep this alpha-numeric.
# @param user
#   The user that should own this profile.
# @param group
#   The group that should own this profile.
# @param template_path
#   Should point to the full path to profile templates for creating the profile.
# @param options
#   The options that are passed to manageprofiles.sh to create the profile. If you specify a value for options, none of the defaults are used. Defaults to '-create -profileName ${profile_name} -profilePath ${profile_base}/${profile_name} -templatePath ${_template_path} -nodeName ${node_name} -hostName ${::fqdn} -federateLater true -cellName standalone' For application servers, the default cell name is standalone. Upon federation (which we aren't doing as part of the profile creation), the application server federates with the specified cell.
# @param wsadmin_user
#   Optional. The username for `wsadmin` authentication if security is enabled.
# @param wsadmin_pass
#   Optional. The password for `wsadmin` authentication if security is enabled.
#
define websphere_application_server::profile::appserver (
  $instance_base,
  $profile_base,
  $cell,
  $node_name,
  $profile_name      = $title,
  $user              = $::websphere_application_server::user,
  $group             = $::websphere_application_server::group,
  $template_path     = undef,
  $options           = undef,
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

  ## Template path. Figure out a sane default if not explicitly specified.
  if ! $template_path {
    $_template_path = "${instance_base}/profileTemplates/app"
  } else {
    $_template_path = $template_path
  }
  validate_absolute_path($_template_path)

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
    cwd     => $instance_base,
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    user    => $user,
    timeout => 900,
    returns => [0, 2],
  }

  # Ensure ownership of profile directory is correct
  websphere_application_server::ownership { $title:
    user    => $user,
    group   => $group,
    path    => "${profile_base}/${profile_name}",
    require => Exec["was_profile_app_${title}"],
  }
}
