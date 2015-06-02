require 'puppet/provider/websphere_helper'

Puppet::Type.type(:websphere_web_server).provide(:wsadmin, :parent => Puppet::Provider::Websphere_Helper) do

  def create
    cmd = "\"AdminTask.createWebServer('#{resource[:node]}', "
    cmd += "'[-name #{resource[:name]} -templateName #{resource[:template]} "
    cmd += "-serverConfig [ -webPort #{resource[:web_port]} -serviceName "
    cmd += "-webInstallRoot #{resource[:install_root]} -webProtocol "
    cmd += "#{resource[:protocol]} -configurationFile #{resource[:config_file]} "
    cmd += "-errorLogfile #{resource[:error_log]} -accessLogfile #{resource[:access_log]} "
    cmd += "-pluginInstallRoot #{resource[:plugin_base]} "
    cmd += "-webAppMapping #{resource[:web_app_mapping]} ] -remoteServerConfig [ "
    cmd += "-adminPort #{resource[:admin_port]} -adminUserID #{resource[:admin_user]} "
    cmd += "-adminPasswd #{resource[:admin_pass]} -adminProtocol "
    cmd += "#{resource[:admin_protocol]} ]]')\""

    self.debug "Running #{cmd}"
    result = wsadmin(:command => cmd, :user => resource[:user])
    self.debug result

    if resource[:propagate_keyring]
      copy_keystore
    end
  end

  def exists?
    cmd = "\"print AdminTask.listServers('[-serverType WEB_SERVER]')\""

    self.debug "Getting list of nodes with jython: #{cmd}"
    result = wsadmin(:command => cmd, :user => resource[:user])
    self.debug result

    unless result =~ /^('|")?#{resource[:name]}\(.*\|server\.xml\)$/
      self.debug "#{resource[:name]} doesn't seem to exist."
      return false
    end
    return true
  end

  def destroy
    Puppet.warning("Removal of server instances not implemented.")
  end

  ## Isn't this beautiful?  This takes care of propagating the plugin keystore
  ## to the server.  There's gotta be a better place/way for this.
  def copy_keystore
cmd = <<-END
cell = AdminControl.getCell()
nodes = AdminTask.listNodes().splitlines()
for node in nodes:
    webservers = AdminTask.listServers('[-serverType WEB_SERVER -nodeName ' + node + ']').splitlines()
    for webserver in webservers:
        webserverName = AdminConfig.showAttribute(webserver, 'name')
        generator = AdminControl.completeObjectName('type=PluginCfgGenerator,*')
        print "Generating plugin-cfg.xml for " + webserverName + " on " + node
        result = AdminControl.invoke(generator, 'generate', '#{resource[:profile_base]}/#{resource[:dmgr_profile]}/config ' + ' ' + cell + ' ' + node + ' ' + webserverName + ' false')
        print "Propagating plugin-cfg.xml for " + webserverName + " on " + node
        result = AdminControl.invoke(generator, 'propagate', '#{resource[:profile_base]}/#{resource[:dmgr_profile]}/config ' + ' ' + cell + ' ' + node + ' ' + webserverName)
        AdminConfig.save()

        try:
           print "Propagating keyring for " + webserverName + " on " + node
           result = AdminControl.invoke(generator, 'propagateKeyring', '#{resource[:profile_base]}/#{resource[:dmgr_profile]}/config ' + ' ' + cell + ' ' + node + ' ' +webserverName)
        except:
           print "error on propagateKerying : " + value

        webserverCON = AdminControl.completeObjectName('type=WebServer,*')
        try:
            print "Stopping " + webserverName + " on " + node
            AdminControl.invoke(webserverCON, 'stop', '[' + cell + ' ' + node + ' ' + webserverName + ']')
        except:
            print "error on stop " + e

        try:
            print "Starting " + webserverName + " on " + node
            result = AdminControl.invoke(webserverCON, 'start', '[' + cell + ' ' + node + ' ' + webserverName + ']')
        except:
            print "Error on start" + e

result = AdminConfig.save()
END
#    cmd = "\"AdminControl.invoke('WebSphere:name=PluginCfgGenerator,"
#    cmd += "process=dmgr,platform=common,node=NODE_DMGR_01,"
#    cmd += "version=8.5.5.4,type=PluginCfgGenerator,mbeanIdentifier=PluginCfgGenerator,cell=CELL_01,spec=1.0', 'propagateKeyring', '[/opt/IBM/WebSphere85/Profiles/PROFILE_DMGR_01/config CELL_01 ihstest ihstest]', '[java.lang.String java.lang.String java.lang.String java.lang.String]')\""

    self.debug "Propagating keyring to '#{resource[:node]}' with jython:\n#{cmd}"
    result = wsadmin(:file => cmd, :user => resource[:user])
    self.debug "Propagation result:\n#{result}"

  end

  def flush
    # do nothing
  end

end
