# Rancher Kubernetes Management HA Install with Ubuntu 18.04, Ansible, RKE, and Nginx

This is a series of playbooks designed to quickly spin up a *Rancher HA Kubernetes* environment with nginx. The playbooks has been tested provisioning 1 nginx load balancer and 1,3,5, and  7 node RKE Clusters with a single `make command`.

### The tech stack consists of the following:

- Ansible
- Docker
- RKE
- Rancher
- Bash/Makefile
- Azure (Optional to provision nodes)

This is an overview of how the project behaves.

You will need at least two publicly available servers to complete this install. Included is an `setup-azure.sh` which provisions nodes on Azure totally optional.

One server will be a dedicated load balancer. You can also use any clouds load balancer, but in this quickstart install uses nginx.

Another server (or several, 1,3,5,7) will become the High Availability (HA) Cluster Nodes onto which we install Rancher 2 and Kubernetes. Each node will fulfill one or several roles in our cluster, all of which will be managed by our Ansible configuration.

**NOTE:** This is a work in progress. As of this writing it will provision an *Ubuntu 18.04* and *Rancher 2.4.x* environment with static hosts.

## Prerequisites and Steps to Run Ansible Playbooks

### Install Docker for Desktop or Docker for Linux

Docker must be installed on your host machine *(machine running ansible playbook)*. This playbook was created on MacOS Catalina. An alpine docker container will be built that has all the prerequisites to run this playbook. A makefile was created to run all the commands needed to create the Rancher HA Install so you don't have to install ansible, kubectl, and rke if you don't wish.

### Provision Nginx Load Balancer and RKE Nodes 

For your convenience `setup-azure.sh` shell script *(optional you can use your own provision script)* is provided to randomly generate nodes for the HA Install. Keep in mind this isn't an *idempotent* script but it will generate random node names. 

The following actions will clone the repository, create a resource group, create a virtual network, and create 4 vm nodes.

```sh
# clone this repo
$ git clone https://github.com/donhighmsft/ansible-rancher-ha.git
#log into Azure
$ az login
#cd into main directory
$ cd ansible-rancher-ha
#makefile creates 4 nodes total
$ make create_azure_vm_setup_nodes nodes=3 
```
`#1 load balancer` *`(rke-lb-ubuntu-node#-vm)`*
`#1 dns name` *`(rke-lb-node#.southcentralus.cloudapp.azure.com)`*
`#3 rke nodes` *`(rke-worker-ubuntu-node#-vm)`*

*#denotes a random generated numbers.*

*`The script opens all network security groups for the virtual machines that will later be configured by ansible`*

Once the virtual machines are created you will need the ip addresses and dns name from the virutal machine to be added to the ansible inventory and all.yml files.

## Inventory

The project uses a static ansible inventory file. Static entries go into `production` file in root folder. All hosts and groups will then be collected into `rancher_kubernetes_nodes`, `rancher_kubernetes_lb`, and `local` for processing by the playbooks themselves. 

`rk8s-lb-1 ansible_host=000.000.000.000 #load balancer ip`
`rk8s-node-1 ansible_host=111.111.111.111 #node 1 ip`
`rk8s-node-2 ansible_host=222.222.222.222 #node 2 ip`
`rk8s-node-3 ansible_host=333.333.333.333 #node 3 ip`

`[rancher_kubernetes_nodes]`
`rk8s-node-1`
`rk8s-node-2`
`rk8s-node-3`

`[rancher_kubernetes_lb]`
`rk8s-lb-1`

## Ansible group_vars

The project uses variables stored in the `group_vars/all.yml` file that will need to put the dns name of your load balancer *`(rke-lb-node#.southcentralus.cloudapp.azure.com)`* and ssh-key *`~/.ssh/id_rsa.pub`* used to ssh into the nodes.

```yaml
# Rancher 2 hostname for the portal
rancher_lb_hostname: rke-lb-node{number}.southcentralus.cloudapp.azure.com

# Must to ssh into the nodes for ansible and rke
usersshkey: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
```

*#denotes a random generated numbers.*

## Build Docker Image or Pull Docker Image.

Before you can run the `Makefile` ansible tasks you must build the docker image or pull it from docker hub repository.

The following `Makefile` command will build the image needed to run Ansible, RKE, and Kubectl in the alpine image.

```sh
make create_docker_image
```

## Ansible inventory test.

The included `Makefile` comes with numerous commands to help provision the Rancher HA Cluster. Before you build the cluster you must make sure you can `ping` the `load balancer` and `rke nodes` with ansible. If the nodes don't return success for *ALL NODES* including the localhost you will not have an successful run.

The following `Makefile` command will ping the 4 nodes created and localhost.

```sh
# Ping the ansible inventory
$ make ping_inv 
```
The following return is a successful ping.

```sh
127.0.0.1 | SUCCESS => { #localhost
    "changed": false,
    "ping": "pong"
}
rk8s-node-1 | SUCCESS => { #rke node 1
    "changed": false,
    "ping": "pong"
}
rk8s-node-3 | SUCCESS => { #rke node 3
    "changed": false,
    "ping": "pong"
}
rk8s-lb-1 | SUCCESS => { #nginx load balancer
    "changed": false,
    "ping": "pong"
}
rk8s-node-2 | SUCCESS => { #rke node 2
    "changed": false,
    "ping": "pong"
}
```

Once the pings come back succesful you can go to the next step and start the installation process.

### Install Ansible roles and Ansible Collections

This Ansible playbooks uses Ansible roles and collections that will need to be installed on the host machine to run the playbooks successfully.

The following `Makefile` commands will install the roles and collections on the host machine.

```sh
# Installs the galaxy roles
make install_roles
```
```sh
# Installs the galaxy collections
make install_collections
```

### Start the Docker, Nginx, RKE, and Rancher Installation process.

Once all the prereqs are completed your ready to run the playbook.

The following `Makefile` command will trigger the Main install.

```sh
make build_nginx_rke_and_rancher
```

This process will take some time so be patient. Depending on how many servers you provision determines the length of the process. You can also manually install using this process following this link [Installing Rancher on a Kubernetes Cluster
](https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/)