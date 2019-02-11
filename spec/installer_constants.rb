
module HelperConstants
  @unsupported_platforms    = ['Suse', 'windows', 'AIX', 'Solaris']
  @websphere_source_dir     = '/opt/sources/ibm_websphere'
  @qa_resources             = '/opt/QA_resources'
  @qa_resource_source       = '10.234.0.63:/shared'
  class << self
    attr_reader :unsupported_platforms, :websphere_source_dir, :qa_resources, :qa_resource_source
  end
end

module WebSphereConstants
  @base_dir               = '/opt/IBM'
  @user                   = 'webadmin'
  @user_home              = '/'
  @group                  = 'webadmins'
  @installation_mode      = 'administrator'
  @instance_base          = @base_dir + '/WebSphere85/AppServer'
  @profile_base           = @instance_base + '/profiles'

  @was_installer          = HelperConstants.qa_resources + '/ibm_websphere/ndtrial'
  @repository             = @was_installer + '/repository.config'

  @class_name             = 'websphere_application_server'
  @instance_name          = 'WebSphere85'
  @package_name           = 'com.ibm.websphere.NDTRIAL.v85'
  @package_version        = '8.5.5000.20130514_1044'
  @update_package_version = '8.5.5004.20141119_1746'

  @fixpack_installer      = HelperConstants.qa_resources + '/ibm_websphere/FP'
  @java_installer         = HelperConstants.qa_resources + '/ibm_websphere/ibm_was_java'
  @java_package           = 'com.ibm.websphere.IBMJAVA.v71'
  @java_version           = '7.1.2000.20141116_0823'

  @cell                   = 'CELL_01'

  @appserver_title        = 'PROFILE_APP_001'
  @dmgr_title             = 'PROFILE_DMGR_02'
  @cluster_title          = 'MyCluster01'
  @cluster_member         = 'AppServer01'

  @dmgr_status            = @profile_base + '/' + @dmgr_title + '/bin/serverStatus.sh'
  @ws_admin = @profile_base + '/' + @dmgr_title + '/bin/wsadmin.sh'

  class << self
    attr_reader :base_dir, :instance_base, :profile_base, :was_installer, :instance_name,
                :package_name, :package_version, :update_package_version, :repository, :class_name, :fixpack_installer,
                :java_installer, :java_package, :java_version, :cell, :appserver_title, :user_home, :installation_mode,
                :dmgr_title, :cluster_title, :cluster_member, :user, :group, :dmgr_status, :ws_admin
  end
end

module FixpackConstants
  @name          = 'WebSphere_8554_fixpack'
  @package       = WebSphereConstants.package_name
  @version       = WebSphereConstants.update_package_version
  @target        = WebSphereConstants.instance_base
  @repository    = WebSphereConstants.fixpack_installer + '/repository.config'
  @package_owner = WebSphereConstants.user
  @package_group = WebSphereConstants.group

  class << self
    attr_reader :package, :version, :target, :repository, :package_owner, :package_group
  end
end

module JDBCProviderConstants
  @jdbc_provider          = 'Puppet Test'
  @dmgr_profile           = WebSphereConstants.dmgr_title
  @profile_base           = WebSphereConstants.profile_base
  @user                   = WebSphereConstants.user
  @scope                  = 'node'
  @cell                   = WebSphereConstants.cell
  @node_name              = 'appNode01'
  @server                 = WebSphereConstants.cluster_member
  @dbtype                 = 'Oracle'
  @providertype           = 'Oracle JDBC Driver'
  @implementation         = 'Connection pool data source'
  @description            = 'Created by Puppet'
  @jdbc_driver            = 'ojdbc6.jar'
  @classpath              = HelperConstants.qa_resources + '/ibm_websphere/oracle/' + @jdbc_driver

  class << self
    attr_reader :jdbc_provider, :dmgr_profile, :profile_base, :user, :scope, :cell, :node_name, :server, :dbtype,
                :providertype, :implementation, :description, :jdbc_driver, :classpath, :oracle_driver_target, :jdbc_driver
  end
end

module JDBCDatasourceConstants
  @jdbc_provider                 = JDBCProviderConstants.jdbc_provider
  @jndi_name                     = 'joshTest'
  @data_store_helper_class       = 'com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper'
  @container_managed_persistence = true
  @url                           = 'jdbc:oracle:thin:@//localhost:1521/sample'
  @description                   = 'Created by Puppet'

  class << self
    attr_reader :jdbc_provider, :jndi_name, :data_store_helper_class, :container_managed_persistence, :url, :description
  end
end

module JavaInstallerConstants
  @java7_name                   = WebSphereConstants.instance_name + '_Java7'
  @java7_installer              = HelperConstants.qa_resources + '/ibm_websphere/ibm_was_java'
  @java7_package                = 'com.ibm.websphere.IBMJAVA.v71'
  @java7_version                = '7.1.2000.20141116_0823'

  class << self
    attr_reader :java7_name, :java7_installer, :java7_package, :java7_version
  end
end

module WebSphereCluster
  @cluster_name = WebSphereConstants.cluster_title

  class << self
    attr_reader :cluster_name
  end
end

module IhsInstance
  @ihs_target                   = 'HTTPServer'
  @package_ihs                  = 'com.ibm.websphere.IHSILAN.v85'
  @package_plugin               = 'com.ibm.websphere.PLGILAN.v85'
  @dmgr_host                    = 'dmgr-centos'

  class << self
    attr_reader :ihs_target, :package_ihs, :package_plugin, :dmgr_host
  end
end
