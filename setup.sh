#  # Executing on centos agents
#  bundle exec rake litmus:tear_down
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::provision_machines
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::pe_server_setup
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::puppet_agents_setup

#  # Executing on redhat, oracle agents
#  bundle exec rake litmus:tear_down
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::provision_machines pe_master=centos-7-x86_64 app_agent=centos-6-x86_64 dmgr_agent=redhat-6-x86_64 ihs_agent=redhat-7-x86_64
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::pe_server_setup
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::puppet_agents_setup

 # Executing on oracle, scientific agents
 bundle exec rake litmus:tear_down
 bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::provision_machines pe_master=centos-7-x86_64 app_agent=oracle-7-x86_64 dmgr_agent=ubuntu-1404-x86_64 ihs_agent=oracle-6-x86_6
 bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::pe_server_setup
 bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::puppet_agents_setup

#  # Executing on centos, redhat agents
#  bundle exec rake litmus:tear_down
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::provision_machines pe_master=centos-7-x86_64 app_agent=ubuntu-1604-x86_64 dmgr_agent=ubuntu-1804-x86_64 ihs_agent=centos-7-x86_64
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::pe_server_setup
#  bundle exec bolt --modulepath spec/fixtures/modules -i ./inventory.yaml plan run websphere_application_server::puppet_agents_setup