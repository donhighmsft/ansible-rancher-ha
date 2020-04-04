# The Main make file to build RKE Rancher Management Server

.PHONY: create_azure_vm_setup_nodes ping_inv create_role install_role install_roles list_roles remove_role\
 run_playbook install_collections rke kube rke_remove_state create_docker_image\
 re_run_rancherinstall re_run_prereqinstall re_run_loadbalancerinstall build_nginx_rke_and_rancher

DOCKERIMAGE=ansible-rke:v1.2 #Docker Image

create_docker_image: ## Build the container
	@docker build -t ${DOCKERIMAGE} .

#create azure test nodes for rke
create_azure_vm_setup_nodes:
	@./setup-azure.sh $(nodes)

#ping management nodes for ansible
ping_inv:
	@docker run --rm \
		-v $(CURDIR):/rke-ansible \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible all -m ping -i production

# create ansible role
create_role:
	@docker run --rm \
		-v $(CURDIR)/roles:/etc/ansible/roles \
		${DOCKERIMAGE} \
		ansible-galaxy init $(role) --init-path=/etc/ansible/roles

# install ansible role
install_role:
	@docker run --rm \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-galaxy install $(role)

# install ansible roles from requirements.yml
install_roles:
	@docker run --rm \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-galaxy role install -r requirements.yml

# list ansible roles 
list_roles:
	@docker run --rm \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-galaxy list

# remove ansible roles
remove_role:
	@docker run --rm \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-galaxy remove $(role)

# install ansible collections from requirements.yml
install_collections:
	@docker run --rm \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-galaxy collection install -r requirements.yml

# main command to install pre-reqs, nginx, rke and rancher
build_nginx_rke_and_rancher:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-playbook -i production site.yml
		
# run ansible playbook with parameters like 
run_playbook:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-playbook -i production site.yml $(cmd)

# re-run ansible play 'rancher' if thier is a problem
re_run_rancherinstall:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-playbook -i production site.yml -t rancher

# re-run ansible play 'prereq' on all nodes if there is a problem
re_run_prereqinstall:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-playbook -i production site.yml -t prereq

# re-run ansible play 'loadbalancer' on lb node if there is a problem
re_run_loadbalancerinstall:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		ansible-playbook -i production site.yml -t loadbalancer

# command for rke
rke:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		rke $(cmd)

# manual remove rke state file if there are issues with rke
rke_remove_state:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		rke remove --config rancher-cluster.yml --force

# manual use kubectl command on rancher management cluster
kube:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		kubectl $(cmd)

# manual use helm command on rancher management cluster		
helm:
	@docker run --rm \
		-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
		-v $(CURDIR):/rke-ansible \
		-w /rke-ansible \
		${DOCKERIMAGE} \
		kubectl $(cmd)