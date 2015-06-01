# Manages the node service for WAS profiles
define websphere_application_server::profile::service (
  $type,
  $profile_base,
  $profile_name = $title,
  $user         = 'root',
  $ensure       = 'running',
  $start        = undef,
  $stop         = undef,
  $status       = undef,
  $restart      = undef,
  $wsadmin_user = undef,
  $wsadmin_pass = undef,
) {

  ## Really, we can create more profile types than this, but this is all we
  ## support right now.
  validate_re($type, '(dmgr|app|appserver|node)')
  validate_absolute_path($profile_base)
  validate_string($profile_name)
  validate_string($user)
  validate_re($ensure, '(running|stopped)')

  if $start   { validate_string($start) }
  if $stop    { validate_string($stop) }
  if $status  { validate_string($status) }
  if $restart { validate_string($restart) }

  if $wsadmin_user and $wsadmin_pass {
    $_auth_string = "-username \"${wsadmin_user}\" -password \"${wsadmin_pass}\" "
  } else {
    $_auth_string = undef
  }

  if ! $status {
    if $type == 'dmgr' {
      $_status = "/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/serverStatus.sh dmgr ${_auth_string} -profileName ${profile_name} | grep -q STARTED'"
    } else {
      $_status = "/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/serverStatus.sh nodeagent -profileName ${profile_name} ${_auth_string}| grep -q STARTED'"
    }
  } else {
    $_status = $status
  }

  if ! $start {
    if $type == 'dmgr' {
      $_start = "/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/startManager.sh -profileName ${profile_name} ${_auth_string}'"
    } else {
      $_start = "/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/startNode.sh ${_auth_string}'"
    }
  } else {
    $_start = $start
  }

  if ! $stop {
    if $type == 'dmgr' {
      $_stop = "/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/stopManager.sh -profileName ${profile_name} ${_auth_string}'"
    } else {
      $_stop = "/bin/su - ${user} -c '${profile_base}/${profile_name}/bin/stopNode.sh ${_auth_string}'"
    }
  } else {
    $_stop = $stop
  }

  if ! $restart {
    $_restart = undef
  } else {
    $_restart = $restart
  }

  service { "was_profile_${title}":
    ensure   => $ensure,
    start    => $_start,
    stop     => $_stop,
    status   => $_status,
    restart  => $_restart,
    provider => 'base',
  }

}
