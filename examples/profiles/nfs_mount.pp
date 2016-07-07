class websphere_profile::nfs_mount { # lint:ignore:autoloader_layout
  file { '/opt/QA_resources':
    ensure => 'directory',
  }
  package { 'nfs-utils': }

  mount { '/opt/QA_resources':
    ensure  => 'mounted',
    device  => 'int-resources.ops.puppetlabs.net:/tank01/resources0/QA_resources',
    fstype  => 'nfs',
    options => 'defaults',
    atboot  => true,
    require => Package['nfs-utils'],
  }
}
