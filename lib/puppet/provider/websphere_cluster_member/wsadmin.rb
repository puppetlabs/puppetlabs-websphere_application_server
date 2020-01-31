# Provider for managing websphere cluster members.
# This parses the cluster member's "server.xml" to read current status, but
# uses the 'wsadmin' tool to make changes.  We cannot modify the xml data, as
# it's basically read-only.
#
require_relative '../websphere_helper'

Puppet::Type.type(:websphere_cluster_member).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_cluster_member`'

  def exists?
    cmd = "\"AdminConfig.getid('/ServerCluster:"
    cmd += "#{resource[:cluster]}/ClusterMember:#{resource[:name]}"
    cmd += "')\""

    debug "Querying members: #{cmd}"

    result = wsadmin(command: cmd, user: resource[:user])

    return true if result =~ %r{'#{resource[:name]}\(cells\/#{resource[:cell]}\/clusters\/#{resource[:cluster]}}
  end

  def create
    cmd = "\"AdminTask.createClusterMember('[-clusterName "
    cmd += resource[:cluster] + ' -memberConfig [-memberNode ' + resource[:node_name]
    cmd += ' -memberName ' + resource[:name] + ' -memberWeight ' + resource[:weight]
    cmd += ' -genUniquePorts ' + resource[:gen_unique_ports].to_s
    cmd += "]]')\""

    result = wsadmin(command: cmd, user: resource[:user], failonfail: false)
    unless result =~ %r{'#{resource[:name]}\(cells\/#{resource[:cell]}\/clusters\/#{resource[:cluster]}}
      msg = "Websphere_cluster_member[#{resource[:name]}]: Failed to "\
               + 'add cluster member. Make sure the node service is running '\
               + "on the remote server. Output: #{result}"
      raise Puppet::Error, "Failed to add cluster member. Run with --debug for details. #{msg}"
    end
    resource.class.validproperties.each do |property|
      value = resource.should(property)
      if value
        @property_hash[property] = value
      end
    end
    true
  end

  def destroy
    cmd = "\"AdminTask.deleteClusterMember('[-clusterName "
    cmd += resource[:cluster] + ' -memberNode ' + resource[:node_name]
    cmd += ' -memberName ' + resource[:name]
    cmd += "]')\""

    wsadmin(command: cmd, user: resource[:user])
  end

  ## Helper method for modifying JVM properties
  def jvm_property(name, value)
    cmd = "\"AdminTask.setJVMProperties('[-nodeName " + resource[:node_name]
    cmd += ' -serverName ' + resource[:name] + ' -'
    cmd += name + ' \"'
    cmd += value
    cmd += '\"'
    cmd += "]')\""
    wsadmin(command: cmd, user: resource[:user])
  end

  def runas_user
    get_xml_val('processDefinitions', 'execution', 'runAsUser')
  end

  def runas_user=(_value)
    cmd = "\"the_id = AdminConfig.list('ProcessExecution','(cells/"
    cmd += resource[:cell]
    cmd += '/nodes/' + resource[:node_name] + '/servers/'
    cmd += resource[:name] + "|server.xml)');"
    cmd += "AdminConfig.modify(the_id, [['runAsUser', '" + resource[:runas_user]
    cmd += "']])\""

    wsadmin(command: cmd, user: resource[:user])
  end

  def runas_group
    get_xml_val('processDefinitions', 'execution', 'runAsGroup')
  end

  def runas_group=(_value)
    cmd = "\"the_id = AdminConfig.list('ProcessExecution','(cells/"
    cmd += resource[:cell]
    cmd += '/nodes/' + resource[:node_name] + '/servers/'
    cmd += resource[:name] + "|server.xml)');"
    cmd += "AdminConfig.modify(the_id, [['runAsGroup', '" + resource[:runas_group]
    cmd += "']])\""

    wsadmin(command: cmd, user: resource[:user])
  end

  def umask
    value = get_xml_val('processDefinitions', 'execution', 'umask')
    ## WAS returns an empty string if the umask is set to 022.
    value = '022' if value.nil? || value == ''
    value
  end

  def umask=(_value)
    cmd = "\"the_id = AdminConfig.list('ProcessExecution','(cells/"
    cmd += resource[:cell]
    cmd += '/nodes/' + resource[:node_name] + '/servers/'
    cmd += resource[:name] + "|server.xml)');"
    cmd += "AdminConfig.modify(the_id, [['umask', '" + resource[:umask]
    cmd += "']])\""

    wsadmin(command: cmd, user: resource[:user])
  end

  def jvm_maximum_heap_size
    get_xml_val('processDefinitions', 'jvmEntries', 'maximumHeapSize')
  end

  def jvm_maximum_heap_size=(_value)
    jvm_property('maximumHeapSize', resource[:jvm_maximum_heap_size])
  end

  def jvm_verbose_mode_class
    get_xml_val('processDefinitions', 'jvmEntries', 'verboseModeClass')
  end

  def jvm_verbose_mode_class=(_value)
    jvm_property('verboseModeClass', resource[:jvm_verbose_mode_class].to_s)
  end

  def jvm_verbose_garbage_collection
    get_xml_val('processDefinitions', 'jvmEntries', 'verboseModeGarbageCollection')
  end

  def jvm_verbose_garbage_collection=(_value)
    jvm_property('verboseModeGarbageCollection', resource[:jvm_verbose_garbage_collection].to_s)
  end

  def jvm_verbose_mode_jni
    get_xml_val('processDefinitions', 'jvmEntries', 'verboseModeJNI')
  end

  def jvm_verbose_mode_jni=(_value)
    jvm_property('verboseModeJNI', resource[:jvm_verbose_mode_jni].to_s)
  end

  def jvm_initial_heap_size
    get_xml_val('processDefinitions', 'jvmEntries', 'initialHeapSize')
  end

  def jvm_initial_heap_size=(_value)
    jvm_property('initialHeapSize', resource[:jvm_initial_heap_size].to_s)
  end

  def jvm_debug_mode
    get_xml_val('processDefinitions', 'jvmEntries', 'debugMode')
  end

  def jvm_debug_mode=(_value)
    jvm_property('debugMode', resource[:jvm_debug_mode])
  end

  def jvm_debug_args
    get_xml_val('processDefinitions', 'jvmEntries', 'debugArgs')
  end

  def jvm_debug_args=(_value)
    jvm_property('debugArgs', "\"#{resource[:jvm_debug_args]}\"")
  end

  def jvm_run_hprof
    get_xml_val('processDefinitions', 'jvmEntries', 'runHProf')
  end

  def jvm_run_hprof=(_value)
    jvm_property('runHProf', resource[:jvm_run_hprof].to_s)
  end

  def jvm_hprof_arguments
    get_xml_val('processDefinitions', 'jvmEntries', 'hprofArguments')
  end

  def jvm_hprof_arguments=(_value)
    # Might need to quote the value
    jvm_property('hprofArguments', "\"#{resource[:jvm_hprof_arguments]}\"")
  end

  def jvm_executable_jar_filename
    value = get_xml_val('processDefinitions', 'jvmEntries', 'executableJarFilename')
    value = '' if value.to_s == ''
    value
  end

  def jvm_executable_jar_filename=(_value)
    # Might need to quote the value
    jvm_property('executableJarFileName', resource[:jvm_executable_jar_filename])
  end

  def jvm_generic_jvm_arguments
    value = get_xml_val('processDefinitions', 'jvmEntries', 'genericJvmArguments')
    ## WAS returns an empty string if the jvm args are default
    value = '' if value.to_s == ''
    value
  end

  def jvm_generic_jvm_arguments=(_value)
    # Might need to quote the value
    jvm_property('genericJvmArguments', resource[:jvm_generic_jvm_arguments])
  end

  def jvm_disable_jit
    get_xml_val('processDefinitions', 'jvmEntries', 'disableJIT')
  end

  def jvm_disable_jit=(_value)
    jvm_property('disableJIT', resource[:jvm_disable_jit].to_s)
  end

  def total_transaction_timeout
    get_xml_val(
      'components[@xmi:type="applicationserver:ApplicationServer"]',
      'services',
      'totalTranLifetimeTimeout',
    )
  end

  def total_transaction_timeout=(_value)
    cmd = "\"the_id = AdminConfig.list('TransactionService','(cells/"
    cmd += resource[:cell]
    cmd += '/nodes/' + resource[:node_name] + '/servers/'
    cmd += resource[:name] + "|server.xml)');"
    cmd += 'AdminConfig.modify(the_id, \'[[totalTranLifetimeTimeout "'
    cmd += resource[:total_transaction_timeout]
    cmd += '"]]\')"'

    wsadmin(command: cmd, user: resource[:user])
  end

  def client_inactivity_timeout
    get_xml_val(
      'components[@xmi:type="applicationserver:ApplicationServer"]',
      'services',
      'clientInactivityTimeout',
    )
  end

  def client_inactivity_timeout=(_value)
    cmd = "\"the_id = AdminConfig.list('TransactionService','(cells/"
    cmd += resource[:cell]
    cmd += '/nodes/' + resource[:node_name] + '/servers/'
    cmd += resource[:name] + "|server.xml)');"
    cmd += 'AdminConfig.modify(the_id, \'[[clientInactivityTimeout "'
    cmd += resource[:client_inactivity_timeout]
    cmd += '"]]\')"'

    wsadmin(command: cmd, user: resource[:user])
  end

  def threadpool_webcontainer_min_size
    get_xml_val(
      'services[@xmi:type="threadpoolmanager:ThreadPoolManager"]',
      'threadPools[@name="WebContainer"]',
      'minimumSize',
    )
  end

  def threadpool_webcontainer_min_size=(_value)
    ## (J|P)ython is whitespace sensitive, and this bit doesn't do well when
    ## being passed as a normal command-line argument.
    cmd = <<-END.unindent
      the_id=AdminConfig.getid('/Node:#{resource[:node_name]}/Server:#{resource[:name]}/')
      tpList=AdminConfig.list('ThreadPool', the_id).split(lineSeparator)
      for tp in tpList:
        if tp.count('WebContainer') == 1:
          tpWebContainer=tp
      AdminConfig.modify(tpWebContainer, [['minimumSize', #{resource[:threadpool_webcontainer_min_size]}]])
      AdminConfig.save()
    END
    wsadmin(file: cmd, user: resource[:user])
  end

  def threadpool_webcontainer_max_size
    get_xml_val(
      'services[@xmi:type="threadpoolmanager:ThreadPoolManager"]',
      'threadPools[@name="WebContainer"]',
      'maximumSize',
    )
  end

  def threadpool_webcontainer_max_size=(_value)
    ## (J|P)ython is whitespace sensitive, and this bit doesn't do well when
    ## being passed as a normal command-line argument.
    cmd = <<-END.unindent
      the_id=AdminConfig.getid('/Node:#{resource[:node_name]}/Server:#{resource[:name]}/')
      tpList=AdminConfig.list('ThreadPool', the_id).split(lineSeparator)
      for tp in tpList:
        if tp.count('WebContainer') == 1:
          tpWebContainer=tp
      AdminConfig.modify(tpWebContainer, [['maximumSize', #{resource[:threadpool_webcontainer_max_size]}]])
      AdminConfig.save()
    END
    wsadmin(file: cmd, user: resource[:user])
    refresh
  end

  def refresh
    flush
  end
end
