#CONSTANTS
module WebSphereConstants
  @base_dir = '/opt/ibm'
  @instance_base          = '/opt/ibm/WebSphere85/AppServer'
  @profile_base           = '/opt/ibm/WebSphere85/AppServer/profiles'

  @was_installer          = '/mnt/QA_resources/ibm_websphere/ndtrial'

  @instance_name          = 'WebSphere85'
  @package_name           = 'com.ibm.websphere.NDTRIAL.v85'
  @package_version        = '8.5.5000.20130514_1044'
  @update_package_version = '8.5.5004.20141119_1746'

  @fixpack_installer      = '/mnt/QA_resources/ibm_websphere/FP'

  @java_installer         = '/mnt/QA_resources/ibm_websphere/ibm_was_java'
  @java_package           = 'com.ibm.websphere.IBMJAVA.v71'
  @java_version           = '7.1.2000.20141116_0823'

  @cell                   = 'CELL_01'

  class << self
    attr_reader :base_dir, :instance_base, :profile_base, :was_installer, :instance_name,
                :package_name,:package_version, :update_package_version, :fixpack_installer,
                :java_installer, :java_package, :java_version, :cell
  end
end

