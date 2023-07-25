# frozen_string_literal: true

require_relative '../websphere_helper'

Puppet::Type.type(:websphere_jdbc_provider).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc <<-DESC
  Provider to manage or create a JDBC Provider for a given JDBC provider at a specific scope.

  Please see the IBM documentation available at:
  https://www.ibm.com/docs/en/was/9.0.5?topic=scripting-jdbcprovidermanagement-command-group-admintask-object

  It is recommended to consult the IBM documentation as the JDBC Provider is a reasonably complex and often
  evolving subject

  This provider will not allow the creation of a dummy instance
  This provider will now allow the changing of:
    * the name of the JDBC Provider
    * the type of a JDBC Provider.
  You need to destroy it first, then create another one with the desired attributes.

  We execute the 'wsadmin' tool to query and make changes, which interprets
  Jython. This means we need to use heredocs to satisfy whitespace sensitivity.
  DESC

  # We are going to use the flush() method to enact all the changes we may perform.
  # This will speed up the application of changes, because instead of changing every
  # attribute individually, we coalesce the changes in one script and execute it once.
  def initialize(val = {})
    super(val)
    @property_flush = {}
    @old_provider_data = {}
    @old_conn_pool_data = {}

    # This hash acts as a translation table between what shows up in the XML file
    # and what the Jython parameters really are. Its format is:
    # 'XML key' => 'Jython param'
    #
    # This translation table allows us to match what we find in the XML files
    # and what we have configured via Jython and see if anything changed.
    # For many of the Jython params, they have identical correspondents in the
    # XML file, but some notable ones are not quite the same.
    #
    # TODO: It would be nice if the translation-table was extendable at runtime, so that
    #       the user can add more translations as they see fit, instead of
    #       waiting for someone to change the provider.
    @xlate_cmd_table = {}

    # Dynamic debugging
    @jython_debug_state = Puppet::Util::Log.level == :debug
  end

  def scope(what)
    file = "#{resource[:profile_base]}/#{resource[:dmgr_profile]}"
    case resource[:scope]
    when 'cell'
      query = "/Cell:#{resource[:cell]}"
      mod   = "cells/#{resource[:cell]}"
      type  = "Cell=#{resource[:cell]}"
      file += "/config/cells/#{resource[:cell]}/resources.xml"
    when 'cluster'
      query = "/Cell:#{resource[:cell]}/ServerCluster:#{resource[:cluster]}"
      mod   = "cells/#{resource[:cell]}/clusters/#{resource[:cluster]}"
      type  = "Cluster=#{resource[:cluster]}"
      file += "/config/cells/#{resource[:cell]}/clusters/#{resource[:cluster]}/resources.xml"
    when 'node'
      query = "/Cell:#{resource[:cell]}/Node:#{resource[:node_name]}"
      mod   = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}"
      type  = "Node=#{resource[:node_name]}"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/resources.xml"
    when 'server'
      query = "/Cell:#{resource[:cell]}/Node:#{resource[:node_name]}/Server:#{resource[:server]}"
      mod   = "cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}"
      type  = "Cell=#{resource[:cell]},Server=#{resource[:server]}"
      file += "/config/cells/#{resource[:cell]}/nodes/#{resource[:node_name]}/servers/#{resource[:server]}/resources.xml"
    else
      raise Puppet::Error, "Unknown scope: #{resource[:scope]}"
    end

    case what
    when 'query'
      query
    when 'mod'
      mod
    when 'type'
      type
    when 'file'
      file
    else
      debug 'Invalid scope request'
    end
  end

  def create
    # Set the scope for this JDBC Provider - Thanks for another way of specifying the containment path!
    jdbc_scope = scope('type')

    # This is a bit stupid - but you can't pass an empty array as an argument to Jython
    # so we have to do this.
    classpath = resource[:classpath].empty? ? '' : "[#{resource[:classpath].join(' ')}]"
    nativepath = resource[:nativepath].empty? ? '' : "[#{resource[:nativepath].join(' ')}]"

    # Put the rest of the resource attributes together 
    extra_attrs = []
    extra_attrs += [['classpath',  "#{classpath}"]]
    extra_attrs += [['nativePath',  "#{nativepath}"]]
    extra_attrs += [['description',  "#{resource[:description]}"]]
    extra_attrs += [['implementationClassname',  "#{resource[:implementation_classname]}"]] unless resource[:implementation_classname].nil?
    extra_attrs_str = extra_attrs.to_s.tr("\"", "'")

    cmd = <<-END.unindent
import AdminUtilities
import re

# Parameters we need for our JDBC Provider creation
scope = '#{jdbc_scope}'
provider_name = '#{resource[:provider_name]}'
db_type = '#{resource[:dbtype]}'
provider_type = '#{resource[:providertype]}'
impl_type = '#{resource[:implementation]}'
extra_attrs = #{extra_attrs_str}



# Enable debug notices ('true'/'false')
AdminUtilities.setDebugNotices('#{@jython_debug_state}')

# Global variable within this script
bundleName = "com.ibm.ws.scripting.resources.scriptLibraryMessage"
resourceBundle = AdminUtilities.getResourceBundle(bundleName)

def normalizeArgList(argList, argName):
  if (argList == []):
    AdminUtilities.debugNotice ("No " + `argName` + " parameters specified. Continuing with defaults.")
  else:
    if (str(argList).startswith("[[") > 0 and str(argList).startswith("[[[",0,3) == 0):
      if (str(argList).find("\\"") > 0):
        argList = str(argList).replace("\\"", "\\'")
    else:
        raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6049E", [argList]))
  return argList
#endDef

# Get the ObjectID of a named object, of a given type at a specified scope.
def getObjectId (scope, objectType, objName):
    objId = AdminConfig.getid(scope+"/"+objectType+":"+objName)
    return objId
#endDef

def createJDBCProviderAtScope( scope, JDBCProvider, dbType, providerType, implType, otherAttrsList=[], failonerror=AdminUtilities._BLANK_ ):
    if(failonerror==AdminUtilities._BLANK_):
        failonerror=AdminUtilities._FAIL_ON_ERROR_
    #endIf
    msgPrefix = "createJDBCProviderAtScope("+`scope`+", "+`JDBCProvider`+", "+`dbType`+", "+`providerType`+", "+`implType`+", "+`otherAttrsList`+", "+`failonerror`+"): "

    try:
        #--------------------------------------------------------------------
        # Create JDBC Provider
        #--------------------------------------------------------------------
        AdminUtilities.debugNotice ("---------------------------------------------------------------")
        AdminUtilities.debugNotice (" AdminJDBC:                  create JDBC Provider")
        AdminUtilities.debugNotice (" Scope:")
        AdminUtilities.debugNotice ("    scope:                                  "+scope)
        AdminUtilities.debugNotice (" JDBC provider:")
        AdminUtilities.debugNotice ("    name:                                   "+JDBCProvider)
        AdminUtilities.debugNotice ("    databaseType:                           "+dbType)
        AdminUtilities.debugNotice ("    providerType:                           "+providerType)
        AdminUtilities.debugNotice ("    implementationType:                     "+implType)
        AdminUtilities.debugNotice (" Additional attributes:")
        AdminUtilities.debugNotice ("    otherAttributesList:                    "+str(otherAttrsList))
        AdminUtilities.debugNotice (" Return: The configuration ID of the new JDBC Provider")
        AdminUtilities.debugNotice ("---------------------------------------------------------------")
        AdminUtilities.debugNotice (" ")

        # This normalization is slightly superfluous, but, what the hey?
        otherAttrsList = normalizeArgList(otherAttrsList, "otherAttrsList")

        # Checking that the passed in parameters are not empty
        # WASL6041E=WASL6041E: Invalid parameter value: {0}:{1}
        if (len(scope) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["scope", scope]))

        if (len(JDBCProvider) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["JDBCProvider", JDBCProvider]))

        if (len(dbType) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["dbType", dbType]))

        if (len(providerType) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["providerType", providerType]))

        if (len(implType) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["implType", implType]))

        # Get the JDBC Provider ID so that we can find its providerType attribute.
        #jdbcProviderId = getObjectId(scope, 'JDBCProvider', JDBCProvider)
        #if (len(jdbcProviderId) == 0):
        #    raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6042E", ["JDBCProvider", JDBCProvider]))

        #prepare for AdminTask command call
        requiredParameters = [["name", JDBCProvider],["scope", scope],["databaseType", dbType],["providerType", providerType],["implementationType", implType]]
        # Convert to list
        otherAttrsList = AdminUtilities.convertParamStringToList(otherAttrsList)

        finalAttrsList = requiredParameters + otherAttrsList

        # Assemble all the command parameters
        finalParameters = []
        for attrs in finalAttrsList:
          attr = ["-"+attrs[0], attrs[1]]
          finalParameters = finalParameters + attr

        AdminUtilities.debugNotice("Creating JDBC Provider %s  with args %s" %(JDBCProvider, str(finalParameters)))

        # Create the JDBC Provider for the given scope
        newObjectId = AdminTask.createJDBCProvider(finalParameters)

        # Save this JDBC Provider
        AdminConfig.save()
        return str(newObjectId)

    except:
        typ, val, tb = sys.exc_info()
        if(typ==SystemExit):  raise SystemExit,`val`
        if (failonerror != AdminUtilities._TRUE_):
            print "Exception: %s %s " % (sys.exc_type, sys.exc_value)
            val = "%s %s" % (sys.exc_type, sys.exc_value)
            raise Exception("ScriptLibraryException: " + val)
        else:
             return AdminUtilities.fail(msgPrefix+AdminUtilities.getExceptionText(typ, val, tb), failonerror)
        #endIf
    #endTry
    AdminUtilities.infoNotice(AdminUtilities._OK_+msgPrefix)
#endDef

# And now - create the JDBC Provider
createJDBCProviderAtScope(scope, provider_name, db_type, provider_type, impl_type, extra_attrs)


END
    # rubocop:enable Layout/IndentHeredoc

    debug "Running command: #{cmd} as user: #{resource[:user]}"
    result = wsadmin(file: cmd, user: resource[:user], failonfail: true)
    if %r{Invalid parameter value "" for parameter "parent config id" on command "create"}.match?(result)
      ## I'd rather handle this in the Jython, but I'm not sure how.
      ## This usually indicates that the server isn't ready on the DMGR yet -
      ## the DMGR needs to do another Puppet run, probably.
      err = <<-EOT
      Could not create JDBC Provider: #{resource[:provider_name]}
      This appears to be due to the remote resource not being available.
      Ensure that all the necessary services have been created and are running
      on this host and the DMGR. If this is the first run, the cluster member
      may need to be created on the DMGR.
      EOT

      raise Puppet::Error, err

    end
    debug "Result:\n#{result}"
  end

  def exists?
    xml_file = scope('file')
    unless File.exist?(xml_file)
      return false
    end

    debug "Retrieving value of #{resource[:provider_name]} from #{xml_file}"
    doc = REXML::Document.new(File.open(xml_file))
    provider_entry = XPath.first(doc, "/xmi:XMI[@xmlns:resources.jdbc]/resources.jdbc:JDBCProvider[@name='#{resource[:provider_name]}']")

    # Populate the @old_provider_data by discovering what are the params for the given JDBC Provider
    debug "Exists? method is loading existing JDBC Provider data attributes/values:"
    XPath.each(provider_entry, "@*")  { |attr|
      debug "#{attr.name} => #{attr.value}"
      xlated_name = @xlate_cmd_table.key?(attr.name) ? @xlate_cmd_table[attr.name] : attr.name
      @old_provider_data[xlated_name.to_sym] = attr.value
    } unless provider_entry.nil?

    # Extract the classpath and nativepath text from all the XML entries for that category. We'll
    # get an empty array if we find nothing - and that is just fine!
    @old_provider_data[:classpath] = (XPath.match(provider_entry, "classpath")).map{ |classpath_entry|
      debug "classpath entry => #{classpath_entry.text}"
      classpath_entry.text
    } unless provider_entry.nil?
    @old_provider_data[:nativepath] = (XPath.match(provider_entry, "nativepath")).map{ |nativepath_entry|
      debug "nativepath entry => #{nativepath_entry.text}"
      nativepath_entry.text
    } unless provider_entry.nil?

    debug "Exists? method result for #{resource[:provider_name]} is: #{!provider_entry.nil?}"
    !provider_entry.nil?
  end

  # Get the resource description
  def description
    @old_provider_data.key?(:description)? @old_provider_data[:description] : ''
  end

  # Set the resource description
  def description=(val)
    @property_flush[:description] = val
  end

  # Get the resource classpath list
  def classpath
    @old_provider_data[:classpath]
  end

  # Set the resource classpath list
  def classpath=(val)
    @property_flush[:classpath] = val
  end

  # Get the resource nativepath list
  def nativepath
    @old_provider_data[:nativepath]
  end

  # Set the resource nativepath list
  def nativepath=(val)
    @property_flush[:nativepath] = val
  end

  # Get the resource implementation classname
  def implementation_classname
    @old_provider_data[:implementationClassName]
  end

  # Set the resource implementation classname
  def implementation_classname=(val)
    @property_flush[:implementationClassName] = val
  end

  # Get the resource class loader isolation flag
  def isolated_class_loader
    @old_provider_data[:isolatedClassLoader]
  end

  # Set the resource class_loader isolation flag
  def isolated_class_loader=(val)
    @property_flush[:isolatedClassLoader] = val
  end

  def destroy
    # Set the scope for this JDBC Resource.
    jdbc_scope = scope('query')
    cmd = <<-END.unindent
import AdminUtilities
import re

# Parameters we need for our JDBC Data Provider deletion
scope = '#{jdbc_scope}'

provider_name = "#{resource[:provider_name]}"

# Enable debug notices ('true'/'false')
AdminUtilities.setDebugNotices('#{@jython_debug_state}')

# Global variable within this script
bundleName = "com.ibm.ws.scripting.resources.scriptLibraryMessage"
resourceBundle = AdminUtilities.getResourceBundle(bundleName)

# Get the ObjectID of a named object, of a given type at a specified scope.
def getObjectId (scope, objectType, objName):
    objId = AdminConfig.getid(scope+"/"+objectType+":"+objName)
    return objId
#endDef

def deleteJDBCProviderAtScope( scope, providerName, failonerror=AdminUtilities._BLANK_ ):
    if(failonerror==AdminUtilities._BLANK_):
        failonerror=AdminUtilities._FAIL_ON_ERROR_
    #endIf
    msgPrefix = "deleteJDBCProviderAtScope("+`scope`+", "+`providerName`+", "+`failonerror`+"): "

    try:
        #--------------------------------------------------------------------
        # Delete JDBC Provider
        #--------------------------------------------------------------------
        AdminUtilities.debugNotice ("---------------------------------------------------------------")
        AdminUtilities.debugNotice (" AdminJDBC:                  delete JDBC Provider")
        AdminUtilities.debugNotice (" Scope:")
        AdminUtilities.debugNotice ("    scope                                   "+scope)
        AdminUtilities.debugNotice (" Provider:")
        AdminUtilities.debugNotice ("    name                                    "+providerName)
        AdminUtilities.debugNotice (" Return: NULL")
        AdminUtilities.debugNotice ("---------------------------------------------------------------")
        AdminUtilities.debugNotice (" ")

        # Checking that the passed in parameters are not empty
        # WASL6041E=WASL6041E: Invalid parameter value: {0}:{1}
        if (len(scope) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["scope", scope]))

        if (len(providerName) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["providerName", providerName]))

        # Get the JDBC Provider ID so that we can delete it safely.
        JDBCProviderId = getObjectId(scope, 'JDBCProvider', providerName)
        if (len(JDBCProviderId) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6042E", ["JDBCProviderId", JDBCProviderId]))
        AdminUtilities.debugNotice("Deleting Provider ID %s" %(JDBCProviderId))

        # Remove the Provider itself now
        AdminTask.deleteJDBCProvider(JDBCProviderId)

        # Save these changes
        AdminConfig.save()
        return

    except:
        typ, val, tb = sys.exc_info()
        if(typ==SystemExit):  raise SystemExit,`val`
        if (failonerror != AdminUtilities._TRUE_):
            print "Exception: %s %s " % (sys.exc_type, sys.exc_value)
            val = "%s %s" % (sys.exc_type, sys.exc_value)
            raise Exception("ScriptLibraryException: " + val)
        else:
             return AdminUtilities.fail(msgPrefix+AdminUtilities.getExceptionText(typ, val, tb), failonerror)
        #endIf
    #endTry
    AdminUtilities.infoNotice(AdminUtilities._OK_+msgPrefix)
#endDef

# And now - Delete the JDBC Provider
deleteJDBCProviderAtScope(scope, provider_name)

END
    # rubocop:enable Layout/IndentHeredoc

    debug "Running command: #{cmd} as user: #{resource[:user]}"
    result = wsadmin(file: cmd, user: resource[:user], failonfail: true)
    if %r{Invalid parameter value "" for parameter "parent config id" on command "destroy"}.match?(result)
      ## I'd rather handle this in the Jython, but I'm not sure how.
      ## This usually indicates that the server isn't ready on the DMGR yet -
      ## the DMGR needs to do another Puppet run, probably.
      err = <<-EOT
      Could not destroy JDBC Provider: #{resource[:provider_name]}
      This appears to be due to the remote resource not being available.
      Ensure that all the necessary services have been created and are running
      on this host and the DMGR. If this is the first run, the cluster member
      may need to be created on the DMGR.
      EOT

      raise Puppet::Error, err

    end
    debug "Result:\n#{result}"
  end

  def flush
    # If we haven't got anything to modify, we've got nothing to flush. Otherwise
    # parse the list of things to do. We basically re-apply the whole settings again
    # to the resource. It is a lot easier to do it this way, than try to apply things
    # in a differential manner (fix just the differences): less prone to error, and
    # less fragile. 
    return if @property_flush.empty?

    # Set the scope for this JDBC Provider - Thanks for another way of specifying the containment path!
    jdbc_scope = scope('query')

    # Put the rest of the resource attributes together 
    extra_attrs = []
    extra_attrs += [['classpath',  "#{resource[:classpath].join(';')}"]]
    extra_attrs += [['nativepath',  "#{resource[:nativepath].join(';')}"]]
    extra_attrs += [['description',  "#{resource[:description]}"]]
    extra_attrs += [['isolatedClassLoader', "#{resource[:isolated_class_loader].to_s}"]]
    extra_attrs += [['implementationClassname',  "#{resource[:implementation_classname]}"]] unless resource[:implementation_classname].nil?
    extra_attrs_str = extra_attrs.to_s.tr("\"", "'")

    cmd = <<-END.unindent
import AdminUtilities
import re

# Parameters we need for our JDBC Provider modification
scope = '#{jdbc_scope}'
provider_name = '#{resource[:provider_name]}'
extra_attrs = #{extra_attrs_str}



# Enable debug notices ('true'/'false')
AdminUtilities.setDebugNotices('#{@jython_debug_state}')

# Global variable within this script
bundleName = "com.ibm.ws.scripting.resources.scriptLibraryMessage"
resourceBundle = AdminUtilities.getResourceBundle(bundleName)

def normalizeArgList(argList, argName):
  if (argList == []):
    AdminUtilities.debugNotice ("No " + `argName` + " parameters specified. Continuing with defaults.")
  else:
    if (str(argList).startswith("[[") > 0 and str(argList).startswith("[[[",0,3) == 0):
      if (str(argList).find("\\"") > 0):
        argList = str(argList).replace("\\"", "\\'")
    else:
        raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6049E", [argList]))
  return argList
#endDef

# Get the ObjectID of a named object, of a given type at a specified scope.
def getObjectId (scope, objectType, objName):
    objId = AdminConfig.getid(scope+"/"+objectType+":"+objName)
    return objId
#endDef

def modifyJDBCProviderAtScope( scope, JDBCProvider, otherAttrsList=[], failonerror=AdminUtilities._BLANK_ ):
    if(failonerror==AdminUtilities._BLANK_):
        failonerror=AdminUtilities._FAIL_ON_ERROR_
    #endIf
    msgPrefix = "modifyJDBCProviderAtScope("+`scope`+", "+`JDBCProvider`+", "+`otherAttrsList`+", "+`failonerror`+"): "

    try:
        #--------------------------------------------------------------------
        # Modify JDBC Provider
        #--------------------------------------------------------------------
        AdminUtilities.debugNotice ("---------------------------------------------------------------")
        AdminUtilities.debugNotice (" AdminJDBC:                  modify JDBC Provider")
        AdminUtilities.debugNotice (" Scope:")
        AdminUtilities.debugNotice ("    scope:                                  "+scope)
        AdminUtilities.debugNotice (" JDBC provider:")
        AdminUtilities.debugNotice ("    name:                                   "+JDBCProvider)
        AdminUtilities.debugNotice (" Additional attributes:")
        AdminUtilities.debugNotice ("    otherAttributesList:                    "+str(otherAttrsList))
        AdminUtilities.debugNotice (" Return: The configuration ID of the new JDBC Provider")
        AdminUtilities.debugNotice ("---------------------------------------------------------------")
        AdminUtilities.debugNotice (" ")

        # This normalization is slightly superfluous, but, what the hey?
        otherAttrsList = normalizeArgList(otherAttrsList, "otherAttrsList")

        # Checking that the passed in parameters are not empty
        # WASL6041E=WASL6041E: Invalid parameter value: {0}:{1}
        if (len(scope) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["scope", scope]))

        if (len(JDBCProvider) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6041E", ["JDBCProvider", JDBCProvider]))

        # Get the JDBC Provider ID so that we can set its attributes.
        JDBCProviderId = getObjectId(scope, 'JDBCProvider', JDBCProvider)
        if (len(JDBCProviderId) == 0):
            raise AttributeError(AdminUtilities._formatNLS(resourceBundle, "WASL6042E", ["JDBCProviderId", JDBCProviderId]))

        #prepare for AdminConfig command call
        requiredParameters = [["name", JDBCProvider]]
        # Convert to list
        otherAttrsList = AdminUtilities.convertParamStringToList(otherAttrsList)

        finalAttrsList = requiredParameters + otherAttrsList

        AdminUtilities.debugNotice("Modifying JDBC Provider %s  with args %s" %(JDBCProvider, str(finalAttrsList).replace(',', '')))

        # The modify command appends the specified unique classpath or nativepath values to the existing values.
        # To completely replace the values, we must first remove the path attributes using the unsetAttributes command.
        AdminConfig.unsetAttributes(JDBCProviderId, '["classpath" "nativepath"]')

        # Modify the JDBC Provider for the given scope
        AdminConfig.modify(JDBCProviderId, str(finalAttrsList).replace(',', ''))

        # Save this JDBC Provider
        AdminConfig.save()
        return

    except:
        typ, val, tb = sys.exc_info()
        if(typ==SystemExit):  raise SystemExit,`val`
        if (failonerror != AdminUtilities._TRUE_):
            print "Exception: %s %s " % (sys.exc_type, sys.exc_value)
            val = "%s %s" % (sys.exc_type, sys.exc_value)
            raise Exception("ScriptLibraryException: " + val)
        else:
             return AdminUtilities.fail(msgPrefix+AdminUtilities.getExceptionText(typ, val, tb), failonerror)
        #endIf
    #endTry
    AdminUtilities.infoNotice(AdminUtilities._OK_+msgPrefix)
#endDef

# And now - create the JDBC Provider
modifyJDBCProviderAtScope(scope, provider_name, extra_attrs)


END
    # rubocop:enable Layout/IndentHeredoc

    debug "Running command: #{cmd} as user: #{resource[:user]}"
    result = wsadmin(file: cmd, user: resource[:user], failonfail: true)
    if %r{Invalid parameter value "" for parameter "parent config id" on command "flush"}.match?(result)
      ## I'd rather handle this in the Jython, but I'm not sure how.
      ## This usually indicates that the server isn't ready on the DMGR yet -
      ## the DMGR needs to do another Puppet run, probably.
      err = <<-EOT
      Could not modify JDBC Provider: #{resource[:provider_name]}
      This appears to be due to the remote resource not being available.
      Ensure that all the necessary services have been created and are running
      on this host and the DMGR. If this is the first run, the cluster member
      may need to be created on the DMGR.
      EOT

      raise Puppet::Error, err

    end
    debug "Result:\n#{result}"
  end
end
