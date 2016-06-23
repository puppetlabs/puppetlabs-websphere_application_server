#CONSTANTS
module HelperConstants
  @unsupported_platforms    = ['Suse','windows','AIX','Solaris']
  @websphere_source_dir     = "/opt/sources/ibm_websphere"
  @oracle_dir               = "/oracle"
  @jdbc_driver              = 'ojdbc6.jar'
  @oracle_driver_target_dir = "#{@oracle_dir}/drivers"
  @oracle_driver_source_dir = "spec/acceptance/drivers"
  @oracle_driver_source     = "#{@oracle_driver_source_dir}/#{@jdbc_driver}"
  @oracle_driver_target     = "#{@oracle_driver_target_dir}/#{@jdbc_driver}"

  class << self
    attr_reader :unsupported_platforms, :websphere_source_dir, :oracle_dir, :jdbc_driver, :oracle_driver_target_dir,
    :oracle_driver_source_dir, :oracle_driver_source, :oracle_driver_target
  end
end

module WebSphereConstants
  @base_dir               = '/opt/IBM'
  @user                   = 'webadmin'
  @group                  = 'webadmins'
  @instance_base          = '/opt/IBM/WebSphere85/AppServer'
  @profile_base           = '/opt/IBM/WebSphere85/AppServer/profiles'

  @was_installer          = '/opt/QA_resources/ibm_websphere/ndtrial'

  @instance_name          = 'WebSphere85'
  @package_name           = 'com.ibm.websphere.NDTRIAL.v85'
  @package_version        = '8.5.5000.20130514_1044'
  @update_package_version = '8.5.5004.20141119_1746'

  @fixpack_installer      = '/opt/QA_resources/ibm_websphere/FP'

  @java_installer         = '/opt/QA_resources/ibm_websphere/ibm_was_java'
  @java_package           = 'com.ibm.websphere.IBMJAVA.v71'
  @java_version           = '7.1.2000.20141116_0823'

  @cell                   = 'CELL_01'

  @appserver_title        = 'PROFILE_APP_001'
  @dmgr_title             = 'PROFILE_DMGR_01'
  @cluster_title          = 'MyCluster01'
  @cluster_member         = 'AppServer01'

  class << self
    attr_reader :base_dir, :instance_base, :profile_base, :was_installer, :instance_name,
                :package_name,:package_version, :update_package_version, :fixpack_installer,
                :java_installer, :java_package, :java_version, :cell, :appserver_title,
                :dmgr_title, :cluster_title, :cluster_member, :user, :group
  end
end
