#Test Working Script To Build Azure IaaS for VM's
# Must az login before running this script

RANCHERRGNUMBER=$((1 + RANDOM % 10)) #Create Random Resource Group Number
RANCHERVMNUMBER=$((1 + RANDOM % 25)) #Create Random Server Number
RKESERVERSCOUNT=${1:-3} #Worker Node Count to Provision defaults to 3
RGPREFIX=don-high #Change Prefix

RG=${RGPREFIX}-rke-rg-${RANCHERRGNUMBER} #Resource Group Random
RGLOCATION=southcentralus #Resource Group Location

echo "Creating Azure RG and VNET.....${RG}....Waiting...."

az group create --name ${RG} --location ${RGLOCATION} # Create Resource Group In Azure

# Create Azure Virtual Network
az network vnet create \
  --name rke-vnet \
  --resource-group ${RG} \
  --subnet-name containers


echo "Creating Rancher RKE HA Install for Nodes....."

# Azure VM for Nginx LoadBalancer
#ubuntu lb
az vm create --resource-group ${RG} \
--name rke-lb-ubuntu-node${RANCHERVMNUMBER}-vm \
--image UbuntuLTS \
--vnet-name rke-vnet \
--subnet containers \
--admin-username rke \
--generate-ssh-keys \
--public-ip-address-dns-name rke-lb-node${RANCHERVMNUMBER} \
--no-wait

echo "Creating loadbalancer node.... rke-lb-ubuntu-node${RANCHERVMNUMBER}-vm"

# Create Virtual Machines 
for (( i=0; i<$RKESERVERSCOUNT; i++ ))
do
   RANCHERVMNUMBER=$((1 + RANDOM % 25))

   #ubuntu server
    az vm create --resource-group ${RG} \
    --name rke-worker-ubuntu-node${RANCHERVMNUMBER}-vm \
    --image UbuntuLTS \
    --vnet-name rke-vnet \
    --subnet containers \
    --admin-username rke \
    --generate-ssh-keys \
    --no-wait

   nodecnt=$((i+1))
   echo "Creating node ${nodecnt} .... rke-worker-ubuntu-node${RANCHERVMNUMBER}-vm"

done

echo "Sleeping........one minute........ before opening NSG's for VM's in ${RG} Resource Group"
sleep 60

echo "Now Opening...."

# Open All Ports on the Virtual Machines
# We Will Control Ports with Ansible Firewall Roles
az vm open-port --ids $(az vm list -g ${RG} --query "[].id" -o tsv) --port '*'

echo "The Resource Group Name ${RG}"
echo "Next Setup your Ansible inventory file named production with the IP Addresses"
echo "Then Setup your all.yml file with the VM DNS Name of your LoadBalancer"