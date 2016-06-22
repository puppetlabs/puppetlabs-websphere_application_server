class websphere_role::dmgr {
  include websphere_profile::nfs_mount
  include websphere_profile::base
  include websphere_profile::dmgr

  Class['websphere_profile::nfs_mount'] -> Class['websphere_profile::base'] -> Class['websphere_profile::dmgr']
}

class websphere_role::appserver {
  include websphere_profile::nfs_mount
  include websphere_profile::base
  include websphere_profile::appserver

  Class['websphere_profile::nfs_mount'] -> Class['websphere_profile::base'] -> Class['websphere_profile::appserver']
}
