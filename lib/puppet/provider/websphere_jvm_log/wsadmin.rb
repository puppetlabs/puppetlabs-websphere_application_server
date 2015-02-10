# Provider to modify WebSphere JVM Logging Properties
#
# This is pretty ugly.  We execute their stupid 'wsadmin' tool to query and
# make changes.  That interprets Jython, which is whitespace sensitive.
# That means we have a bunch of heredocs to provide our commands for it.
require 'puppet/provider/websphere_helper'

Puppet::Type.type(:websphere_jvm_log).provide(:wsadmin, :parent => Puppet::Provider::Websphere_Helper) do

  def scope(what)
    file = resource[:profile_base] + '/' + resource[:profile]

    case resource[:scope]
    when 'node'
      query = '/Cell:' + "#{resource[:cell]}" + '/Node:' + "#{resource[:node]}/Server:nodeagent"
      mod   = 'cells/' + "#{resource[:cell]}" + '/nodes/' + "#{resource[:node]}"
      file  += '/config/cells/' + resource[:cell] + '/nodes/'  + resource[:node] + '/servers/nodeagent/server.xml'
    when 'server'
      query = '/Cell:' + "#{resource[:cell]}" + '/Node:' + "#{resource[:node]}" + '/Server:' + "#{resource[:server]}"
      mod   = 'cells/' + "#{resource[:cell]}" + '/nodes/' + "#{resource[:node]}" + '/servers/' + "#{resource[:server]}"
      file  += '/config/cells/' + resource[:cell] + '/nodes/'  + resource[:node] + '/servers/' + resource[:server] + '/server.xml'
    else
      raise Puppet::Error, "Unknown scope: #{resource[:scope]}"
    end

    case what
    when 'query'
      query
    when 'mod'
      mod
    when 'file'
      file
    else
      self.debug "Invalid scope request"
    end
  end

  def set_log_prop(args={})
    case args[:type]
    when 'err'
      type = 'errorStreamRedirect'
    when 'out'
      type = 'outputStreamRedirect'
    end
cmd = <<-END
scope=AdminConfig.getid('#{scope('query')}/')
log=AdminConfig.showAttribute(scope, '#{type}')
AdminConfig.modify(log, [['#{args[:setting]}', '#{args[:val]}']])
AdminConfig.save()
END
    self.debug "Running #{cmd}"
    result = wsadmin(:file => cmd, :user => resource[:user])
    self.debug result
  end

  def err_filename
    get_xml_val('errorStreamRedirect','','fileName', scope('file'))
  end

  def err_filename=(val)
    set_log_prop(
      :type    => 'err',
      :setting => 'fileName',
      :val     => resource[:err_filename]
    )
  end

  def err_rollover_type
    get_xml_val('errorStreamRedirect','','rolloverType', scope('file'))
  end

  def err_rollover_type=(val)
    set_log_prop(
      :type    => 'err',
      :setting => 'rolloverType',
      :val     => resource[:err_rollover_type]
    )
  end

  def err_rollover_size
    get_xml_val('errorStreamRedirect','','rolloverSize', scope('file'))
  end

  def err_rollover_size=(val)
    set_log_prop(
      :type    => 'err',
      :setting => 'rolloverSize',
      :val     => resource[:err_rollover_size]
    )
  end

  def err_maxnum
    get_xml_val('errorStreamRedirect','','maxNumberOfBackupFiles', scope('file'))
  end

  def err_maxnum=(val)
    set_log_prop(
      :type    => 'err',
      :setting => 'maxNumberOfBackupFiles',
      :val     => resource[:err_maxnum]
    )
  end

  def err_start_hour
    get_xml_val('errorStreamRedirect','','baseHour', scope('file'))
  end

  def err_start_hour=(val)
    set_log_prop(
      :type    => 'err',
      :setting => 'baseHour',
      :val     => resource[:err_start_hour]
    )
  end

  def err_rollover_period
    get_xml_val('errorStreamRedirect','','rolloverPeriod', scope('file'))
  end

  def err_rollover_period=(val)
    set_log_prop(
      :type    => 'err',
      :setting => 'rolloverPeriod',
      :val     => resource[:err_rollover_period]
    )
  end

  def out_filename
    get_xml_val('outputStreamRedirect','','fileName', scope('file'))
  end

  def out_filename=(val)
    set_log_prop(
      :type    => 'out',
      :setting => 'fileName',
      :val     => resource[:out_filename]
    )
  end

  def out_rollover_type
    get_xml_val('outputStreamRedirect','','rolloverType', scope('file'))
  end

  def out_rollover_type=(val)
    set_log_prop(
      :type    => 'out',
      :setting => 'rolloverType',
      :val     => resource[:out_rollover_type]
    )
  end

  def out_rollover_size
    get_xml_val('outputStreamRedirect','','rolloverSize', scope('file'))
  end

  def out_rollover_size=(val)
    set_log_prop(
      :type    => 'out',
      :setting => 'rolloverSize',
      :val     => resource[:out_rollover_size]
    )
  end

  def out_maxnum
    get_xml_val('outputStreamRedirect','','maxNumberOfBackupFiles', scope('file'))
  end

  def out_maxnum=(val)
    set_log_prop(
      :type    => 'out',
      :setting => 'maxNumberOfBackupFiles',
      :val     => resource[:out_maxnum]
    )
  end

  def out_start_hour
    get_xml_val('outputStreamRedirect','','baseHour', scope('file'))
  end

  def out_start_hour=(val)
    set_log_prop(
      :type    => 'out',
      :setting => 'baseHour',
      :val     => resource[:out_start_hour]
    )
  end

  def out_rollover_period
    get_xml_val('outputStreamRedirect','','rolloverPeriod', scope('file'))
  end

  def out_rollover_period=(val)
    set_log_prop(
      :type    => 'out',
      :setting => 'rolloverPeriod',
      :val     => resource[:out_rollover_period]
    )
  end

  def flush
    sync_node
    restart_server
  end

end
