# Defined type to manage IBM packages and ownership
define websphere::package (
  $version    = undef,
  $repository = undef,
  $target     = undef,
  $response   = undef,
  $ensure     = 'present',
  $package    = $title,
  $imcl_path  = undef,
  $options    = undef,
  $chown      = true,
  $user       = $::websphere::user,
  $group      = $::websphere::group,
) {

  # If no response file is provided, we need a package version, name,
  # repository, and target.  Otherwise, a response file can potentially include
  # those values.
  if ! $response {

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
    validate_absolute_path($response)
  }

  ibm_pkg { $title:
    ensure     => $ensure,
    package    => $package,
    version    => $version,
    repository => $repository,
    target     => $target,
    response   => $response,
    imcl_path  => $imcl_path,
    options    => $options,
  }

  if $chown {
    websphere::ownership { "pkg_${title}":
      user      => $user,
      group     => $group,
      path      => $target,
      subscribe => Ibm_pkg[$title],
    }
  }
}
