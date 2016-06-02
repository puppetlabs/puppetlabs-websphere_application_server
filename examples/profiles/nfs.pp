class websphere_profile::nfs_mount {
  file {"/mnt/QA_resources":
    ensure => "directory",
  }
  package { 'nfs-common': }

  mount { "/mnt/QA_resources":
    device  => "int-resources.ops.puppetlabs.net:/tank01/resources0/QA_resources",
    fstype  => "nfs",
    ensure  => "mounted",
    options => "defaults",
    atboot  => true,
    require => Package['nfs-common'],
  }
}
