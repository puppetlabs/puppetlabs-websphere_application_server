# == Define: websphere::instance
#
# Manage installations of WebSphere
#
# === Parameters
#
# === Examples
#
#   websphere::instance { 'WebSphere85':
#     instance_base => '/opt/IBM',
#   }
#
# === Authors
#
# Josh Beard <beard@puppetlabs.com>
#
# === Copyright
#
# Copyright 2015 Puppet Labs, Inc.
#
define websphere::instance (
  $base_dir                  = $::websphere::base_dir,
  $target                    = undef,
  $package                   = undef,
  $version                   = undef,
  $repository                = undef,
  $response_file             = undef,
  $install_options           = undef,
  $imcl_path                 = undef,
  $profile_base              = undef,
  $manage_user               = false,
  $manage_group              = false,
  $user                      = $::websphere::user,
  $group                     = $::websphere::group,
  $user_home                 = undef,
) {

  # The target is where WebSphere will get installed. If it isn't set,
  # we default it to the base_dir from the base class/title/AppServer.  This
  # is pretty much IBM's default.
  if ! $target {
    $_target = "${base_dir}/${title}/AppServer"
  } else {
    $_target = $target
  }
  validate_absolute_path($_target)

  # A reasonable default user home if we're managing it for this instance.
  if ! $user_home {
    $_user_home = $_target
  } else {
    $_user_home = $user_home
  }

  # This is the IBM default. E.g. /opt/IBM/WebSphere/AppServer/profiles
  # Yes - right in the installation path.
  if ! $profile_base {
    $_profile_base = "${_target}/profiles"
  } else {
    $_profile_base = $profile_base
  }

  # If no response file is provided, we need a package version, name,
  # repository, and target.  Otherwise, a response file can potentially include
  # those values.
  if ! $response_file {

    if !$package or !$version or !$repository or !$target {
      fail('package_name, package_version, target and repository are required
      when a response file is not provided.')
    }

    validate_absolute_path($repository)

    # The imcl path is optional.  We do our best to autodiscover it, but
    # this can be used if all else fails (or if preferences vary).
    if $imcl_path {
      validate_absolute_path($imcl_path)
    }

  } else {
    validate_absolute_path($response_file)
  }


  # We want a sanitized instance name derived from the title that we can use
  # in various places that need only alpha-numeric.
  $instance_name = regsubst($title,'[^0-9a-zA-Z_]+','', 'G')

  # Optionally manage a user for this specific instance.  By default, we'll
  # just let the base class (::websphere) handle this.  There may be some
  # cases where instances should have their own independent users/groups, and
  # this allows for that.
  validate_bool($manage_user)
  if $manage_user {
    user { $user:
      ensure => 'present',
      home   => $_user_home,
      gid    => $group,
    }
  }
  validate_bool($manage_group)
  if $manage_group {
    group { $group:
      ensure => 'present',
    }
  }

  websphere::package { $title:
    ensure     => 'present',
    package    => $package,
    version    => $version,
    target     => $_target,
    response   => $response_file,
    options    => $install_options,
    repository => $repository,
    imcl_path  => $imcl_path,
    chown      => true,
    user       => $user,
    group      => $group,
  }

  file { $_profile_base:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    require => Websphere::Package[$title],
  }

  # Create some facts based on the parameter values
  concat::fragment { "${instance_name}_facts":
    target  => '/etc/puppetlabs/facter/facts.d/websphere.yaml',
    content => template("${module_name}/facts/was_instance.yaml.erb"),
    require => Websphere::Package[$title],
  }

}
