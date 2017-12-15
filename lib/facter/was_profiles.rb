##
## Facts for IBM WebSphere Application Server
##
## Facts:
##   websphere_profiles
##     A comma-separated list of all WAS 'profiles' on a system
##   websphere_$profile_version
##     The WAS version reported by a profile via versionInfo.sh
##   websphere_$profile_$cell_soap
##     The SOAP port for a profile cell.  Needed for federation.
##
require 'rexml/document'
require 'yaml'
include REXML
# TODO: see if this can be configurable based on settings::vardir
was_file = '/etc/puppetlabs/facter/facts.d/websphere.yaml'


if File.exist?(was_file)
  Facter.debug "Found #{was_file}"
  was_facts = YAML.load_file(was_file)

  ## Get each profile base dir from the facts.d file
  profiles_path = was_facts.select { |k,v| k.to_s.match(/.*_profile_base.*/) }
  instances = was_facts.select { |k,v| k.to_s.match(/.*_name.*/) }
else
  Facter.debug "Could not find #{was_file}"
  profiles_path = []
  instances = []
end

# finds the IIM installed.xml file in /opt or /home/*/var. This method was added
# because this file is no longer guaranteed to live at '/var/ibm/InstallationManager/installed.xml'
#
# @returns String installed_xml_path path to the first installed.xml file found
#   (there should only be one on the system)
def find_installed_xml
  require 'find'
  glob = Dir.glob('/home/*/var/').join(',')

  installed_xml_path = ""
  begin
    Find.find("/opt/", glob) { |path| installed_xml_path = path if path =~ /InstallationManager\/installed.xml/ }
  rescue Errno::ENOENT => e
    raise("There was a problem finding installed.xml: #{e}")
  end
  installed_xml_path
end

## Iterate over each instance that's listed in the "facts.d" fact to determine
## its version.  We're doing it this way because we're relying on arbitrary user-provided
## install locations (stored in facts.d).
## We want the version and package name.  We'll be able to use this for
## installing IBM "fix packs"
##
## There is a chance that they'll have two instances with the same name, but
## different install paths.  If that's the case, this just isn't going to work
## as expected.
instances.each do |key,instance|
  im_file = find_installed_xml
  target = Facter.value("#{instance}_target")

  version = nil
  package = nil

  puts "CHECKING TO SEE IF #{im_file} EXISTS"

  if File.exists?(im_file)
    Facter.debug "Found #{im_file}"
    imdata = REXML::Document.new(File.read(im_file))
    path = XPath.first(imdata, "//installInfo/location[@path='#{target}']/package[starts-with(@name, 'IBM WebSphere Application Server')]")
    if path
      version = XPath.first(path, '@version')
      package = XPath.first(path, '@id')
    end
  else
    Facter.debug "Could not find #{im_file}"
    version = "unknown"
  end

  Facter.add("#{instance}_version") do
    setcode do
      version.to_s.chomp
    end
  end

  Facter.add("#{instance}_package") do
    setcode do
      package.to_s.chomp
    end
  end
end


## We'll build an array for a list of JUST the profiles and return that as its
## own fact
profiles_arr = []

profiles_path.each do |key,aprofile|
  ## Build a hash of profiles.
  ## This will include the cells in a profile and the nodes in that cell.
  Dir["#{aprofile}/*/"].map { |a| File.basename(a) }.each do |profile|
    profiles_arr << profile

    ## List of cells
    Dir["#{aprofile}/#{profile}/config/cells/*/"].map { |a| File.basename(a) }.each do |cell|

      ## List of nodes in a cell
      Dir["#{aprofile}/#{profile}/config/cells/#{cell}/nodes/*/"].map { |a|
        File.basename(a)
      }.each do |cell_node|

        ## Ports in a cell
        serverindex = REXML::Document.new(File.read("#{aprofile}/#{profile}/config/cells/#{cell}/nodes/#{cell_node}/serverindex.xml"))
        soap = XPath.first(serverindex, '//serverEntries/specialEndpoints[@endPointName="SOAP_CONNECTOR_ADDRESS"]/endPoint/@port')

        if soap
          Facter.add("websphere_#{profile}_#{cell}_#{cell_node}_soap") do
            setcode do
              soap.to_s
            end
          end
        end

      end
    end
  end
end

Facter.add(:websphere_profiles) do
  setcode do
    profiles_arr.join(',')
  end
end
