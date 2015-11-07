require 'erb'
require 'master_manipulator'

require 'websphere_helper'
test_name 'FM-3808 - Cxxx - download IBM installers'

url = 'http://int-resources.ops.puppetlabs.net/QA_resources/ibm_websphere'

#ndtrial
ndtrial_part1 = 'was.repo.8550.ndtrial_part1.zip'
ndtrial_part2 = 'was.repo.8550.ndtrial_part2.zip'
ndtrial_part3 = 'was.repo.8550.ndtrial_part3.zip'
uncompress_ndtrial = "/ibminstallers/ibm/ndtrial"

#ibm java 7
ibm_java7_part1 = '7.1.2.0-WS-IBMWASJAVA-part1.zip'
ibm_java7_part2 = '7.1.2.0-WS-IBMWASJAVA-part2.zip'
uncompress_java7 = "/ibminstallers/ibm/java7"

#IBM FixPatches
was_fixpatch_part1 = '8.5.5-WS-WAS-FP0000004-part1.zip'
was_fixpatch_part2 = '8.5.5-WS-WAS-FP0000004-part2.zip'
uncompress_fp = "/ibminstallers/ibm/fp"

# Manually install  websphere_application_server from github
# github_was = 'websphere_application_server.tar.gz'
# on(master, puppet('module install dsestero-download_uncompress -v 1.2.0'))
# download_and_uncompress(master, url, github_was, "/etc/puppetlabs/code/environments/production/modules")
# on(master, "ls -lt /etc/puppetlabs/code/environments/production/modules")


confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|

    # Download and uncompress websphere trial version
    if agent.file_exist?(uncompress_ndtrial) == nil
      puts "The folder #{uncompress_ndtrial} already exist!!"
    else
      step 'Download and uncompress webspher installer'
      download_and_uncompress(agent, url, ndtrial_part1, uncompress_ndtrial)
      download_and_uncompress(agent, url, ndtrial_part2, uncompress_ndtrial)
      download_and_uncompress(agent, url, ndtrial_part3, uncompress_ndtrial)
    end

    # Download and uncompress IBM Java 7
    if agent.file_exist?(uncompress_java7)
      puts "The folder #{uncompress_java7} already exist!!"
    else
      step 'Download and uncompress webspher installer'
      download_and_uncompress(agent, url, ibm_java7_part1, uncompress_java7)
      download_and_uncompress(agent, url, ibm_java7_part2, uncompress_java7)
    end

    # Download and uncompress Websphere fixpatches
    if agent.file_exist?(uncompress_fp)
      puts "The folder #{uncompress_fp} already exist!!"
    else
      step 'Download and uncompress webspher fix patches'
      download_and_uncompress(agent, url, was_fixpatch_part1, uncompress_fp)
      download_and_uncompress(agent, url, was_fixpatch_part2, uncompress_fp)
    end
  end
end

