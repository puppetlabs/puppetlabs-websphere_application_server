# Defined type for managing WebSphere clusters in a cell.
# This is really just a wrapper around our native types, but it makes it a
# little easier and abstracted to the end user, especially considering the
# exported/collected resources.
#
define websphere::cluster (
  $profile_base,
  $dmgr_profile,
  $cell,
  $ensure           = 'present',
  $user             = $::websphere::user,
  $cluster          = $title,
  $collect_members  = true,
) {

  websphere_cluster { $cluster:
    ensure       => $ensure,
    profile_base => $profile_base,
    dmgr_profile => $dmgr_profile,
    user         => $user,
  }

  if $collect_members {

    ## Collect any or our exported defined types
    Websphere::Cluster::Member <<| cell == $cell |>> {
      profile_base => $profile_base,
      dmgr_profile => $dmgr_profile,
      user         => $user,
      require      => Websphere_cluster[$name],
    }

    ## Collect any of the individual resources
    Websphere_cluster_member <<| cell == $cell |>> {
      profile_base => $profile_base,
      dmgr_profile => $dmgr_profile,
      user         => $user,
      require      => Websphere_cluster[$name],
    }

    Websphere_cluster_member_service <<| cell == $cell |>> {
      profile_base => $profile_base,
      dmgr_profile => $dmgr_profile,
      user         => $user,
    }
  }
}
