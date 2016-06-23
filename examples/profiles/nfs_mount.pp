class websphere_profile::nfs_mount {
  file {"/opt/QA_resources":
    ensure => "directory",
  }
  package { 'nfs-utils': }

  mount { "/opt/QA_resources":
    device  => "int-resources.ops.puppetlabs.net:/tank01/resources0/QA_resources",
    fstype  => "nfs",
    ensure  => "mounted",
    options => "defaults",
    atboot  => true,
    require => Package['nfs-utils'],
  }
}
