require_relative '../websphere_helper'
#
Puppet::Type.type(:websphere_jdbc_datasource_jaas_auth_data).provide(:wsadmin, parent: Puppet::Provider::Websphere_Helper) do
  desc 'wsadmin provider for `websphere_jdbc_datasource_jaas_auth_data`'

  def exists?
    xml_file = resource[:profile_base] + '/' + resource[:dmgr_profile] + '/config/cells/' + resource[:cell] + '/security.xml'
    unless File.exist?(xml_file)
      return false
    end
    doc = REXML::Document.new(File.open(xml_file))
    path = REXML::XPath.first(doc, "//security:Security/authDataEntries[@alias='#{resource[:name]}'])")

    path ? true : false
  end

  def create
    jaas_attributes = [['alias', resource[:name]], ['userId', resource[:user_id]], ['password', resource[:password]], ['description', resource[:description]]]

    cmd = <<-EOS
security = AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/');
AdminConfig.create('JAASAuthData', security, #{jaas_attributes});
AdminConfig.save();
EOS

    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Created JAAS auth data #{name}. result: #{result}"
    @property_hash.clear
  end

  def destroy
    # AdminConfig.getid('/Cell:CELL_01/Security:/JAASAuthData:/')
    cmd = <<-EOS
jaasAuthData = AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/JAASAuthData:/').splitlines();
for jaas in jaasAuthData:
  if (AdminConfig.showAttribute(jaas, 'alias') == "#{resource[:name]}"):
    AdminConfig.remove(jaas);
AdminConfig.save();
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug "Removed JAAS auth data #{resource[:name]}. result: #{result}"
    @property_hash.clear
  end

  # @private
  # Helper method
  def get_property_value(prop)
    xml_file = resource[:profile_base] + '/' + resource[:dmgr_profile] + '/config/cells/' + resource[:cell] + '/security.xml'

    unless File.exist?(xml_file)
      return false
    end

    doc = REXML::Document.new(File.open(xml_file))
    path = REXML::XPath.first(doc, "//security:Security/authDataEntries[@alias='#{resource[:name]}'])")

    unless path
      return nil
    end
    value = REXML::XPath.first(path, "@#{prop}")
    debug "Exists? Found match for #{resource[:name]}. #{prop} is: #{value}" if value

    value.nil? ? nil : value.to_s
  end

  def password
    value = get_property_value('password')

    # compare encrypted password from XML to the password defined that we'll encrpyt
    install_path = resource[:profile_base].split('/')[0..-2].join('/')
    java_path = "#{install_path}/java/bin/java"

    unless File.exist?(java_path)
      # Try to find java install
      # WebSphere9 doesn't come with Java prepackaged
      java_path = "#{install_path}/java/8.0/bin/java"
      unless File.exist?(java_path)
        raise Error, 'Cannot configure password for JAAS auth data. Java not found in hardcoded locations.'
      end
    end
    cmd               = "#{java_path} -Xmx12m -Djava.ext.dirs=#{install_path}/plugins:#{install_path}/lib com.ibm.ws.security.util.PasswordEncoder '#{resource[:password]}'"
    new_password_xor  = `#{cmd}`
    new_password_xor  = new_password_xor.split.last[1..-2]

    (value.to_s == new_password_xor.to_s) ? resource[:password] : 'different'
  end

  def user_id
    value = get_property_value('userId')
    value.nil? ? nil : value.to_s
  end

  def description
    value = get_property_value('description')
    value.nil? ? nil : value.to_s
  end

  def password=(value)
    @property_hash[:password] = value
  end

  def user_id=(value)
    @property_hash[:user_id] = value
  end

  def description=(value)
    @property_hash[:description] = value
  end

  # @private
  # Helper method
  def modified_attributes_list_list
    # Only add defined values
    list_list = []
    list_list << ['userId', @property_hash[:user_id]] if @property_hash[:user_id]
    list_list << ['password', @property_hash[:password]] if @property_hash[:password]
    list_list << ['description', @property_hash[:description]] if @property_hash[:description]
    list_list
  end

  def flush
    return if @property_hash.empty?
    cmd = <<-EOS
jaasAuthData = AdminConfig.getid('/Cell:#{resource[:cell]}/Security:/JAASAuthData:/').splitlines();
for jaas in jaasAuthData:
    if (AdminConfig.showAttribute(jaas, 'alias') == "#{resource[:name]}"):
        AdminConfig.modify(jaas, #{modified_attributes_list_list});
AdminConfig.save();
EOS
    debug "Running #{cmd}"
    result = wsadmin(file: cmd, user: resource[:user])
    debug result
  end
end
