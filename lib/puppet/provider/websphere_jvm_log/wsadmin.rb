# frozen_string_literal: true

require_relative '../websphere_helper'

Puppet::Type.type(:websphere_jvm_log).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc <<-DESC
    Provider to modify WebSphere JVM Logging Properties ( `websphere_jvm_log` )

    We execute the 'wsadmin' tool to query and make changes, which interprets
    Jython. This means we need to use heredocs to satisfy whitespace sensitivity.
    DESC
  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:profile]}"

    case resource[:scope]
    when :node
      query = "/Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:nodeagent"
      mod = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/nodeagent/server.xml"
    when :server
      query = "/Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:#{resource[:server]}"
      mod = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/server.xml"
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
      debug 'Invalid scope request'
    end
  end

  def log_prop_equals(args = {})
    case args[:type]
    when 'err'
      type = 'errorStreamRedirect'
    when 'out'
      type = 'outputStreamRedirect'
    end
    cmd = <<-END.unindent
    scope=AdminConfig.getid('#{scope('query')}/')
    log=AdminConfig.showAttribute(scope, '#{type}')
    AdminConfig.modify(log, [['#{args[:setting]}', '#{args[:val]}']])
    AdminConfig.save()
    END
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
  end

  def err_filename
    get_xml_val('errorStreamRedirect', '', 'fileName', scope('file'))
  end

  def err_filename=(_val)
    log_prop_equals(
      type: 'err',
      setting: 'fileName',
      val: resource[:err_filename],
    )
  end

  def err_rollover_type
    get_xml_val('errorStreamRedirect', '', 'rolloverType', scope('file'))
  end

  def err_rollover_type=(_val)
    log_prop_equals(
      type: 'err',
      setting: 'rolloverType',
      val: resource[:err_rollover_type],
    )
  end

  def err_rollover_size
    get_xml_val('errorStreamRedirect', '', 'rolloverSize', scope('file'))
  end

  def err_rollover_size=(_val)
    log_prop_equals(
      type: 'err',
      setting: 'rolloverSize',
      val: resource[:err_rollover_size],
    )
  end

  def err_maxnum
    get_xml_val('errorStreamRedirect', '', 'maxNumberOfBackupFiles', scope('file'))
  end

  def err_maxnum=(_val)
    log_prop_equals(
      type: 'err',
      setting: 'maxNumberOfBackupFiles',
      val: resource[:err_maxnum],
    )
  end

  def err_start_hour
    get_xml_val('errorStreamRedirect', '', 'baseHour', scope('file'))
  end

  def err_start_hour=(_val)
    log_prop_equals(
      type: 'err',
      setting: 'baseHour',
      val: resource[:err_start_hour],
    )
  end

  def err_rollover_period
    get_xml_val('errorStreamRedirect', '', 'rolloverPeriod', scope('file'))
  end

  def err_rollover_period=(_val)
    log_prop_equals(
      type: 'err',
      setting: 'rolloverPeriod',
      val: resource[:err_rollover_period],
    )
  end

  def out_filename
    get_xml_val('outputStreamRedirect', '', 'fileName', scope('file'))
  end

  def out_filename=(_val)
    log_prop_equals(
      type: 'out',
      setting: 'fileName',
      val: resource[:out_filename],
    )
  end

  def out_rollover_type
    get_xml_val('outputStreamRedirect', '', 'rolloverType', scope('file'))
  end

  def out_rollover_type=(_val)
    log_prop_equals(
      type: 'out',
      setting: 'rolloverType',
      val: resource[:out_rollover_type],
    )
  end

  def out_rollover_size
    get_xml_val('outputStreamRedirect', '', 'rolloverSize', scope('file'))
  end

  def out_rollover_size=(_val)
    log_prop_equals(
      type: 'out',
      setting: 'rolloverSize',
      val: resource[:out_rollover_size],
    )
  end

  def out_maxnum
    get_xml_val('outputStreamRedirect', '', 'maxNumberOfBackupFiles', scope('file'))
  end

  def out_maxnum=(_val)
    log_prop_equals(
      type: 'out',
      setting: 'maxNumberOfBackupFiles',
      val: resource[:out_maxnum],
    )
  end

  def out_start_hour
    get_xml_val('outputStreamRedirect', '', 'baseHour', scope('file'))
  end

  def out_start_hour=(_val)
    log_prop_equals(
      type: 'out',
      setting: 'baseHour',
      val: resource[:out_start_hour],
    )
  end

  def out_rollover_period
    get_xml_val('outputStreamRedirect', '', 'rolloverPeriod', scope('file'))
  end

  def out_rollover_period=(_val)
    log_prop_equals(
      type: 'out',
      setting: 'rolloverPeriod',
      val: resource[:out_rollover_period],
    )
  end

  def flush
    sync_node
    restart_server
  end
end
