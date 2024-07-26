group=azure-load-balancer-introduction
location=eastus
username=azureuser
password='Test1234!@#$'
vnetname=vm-vnet

# Create the resource group
az group create -g $group -l $location

# Create Virtual Network and Subnet
az network vnet create \
  --name $vnetname \
  --resource-group $group \
  --location $location \
  --address-prefixes '192.168.0.0/16' \
  --subnet-name subnet \
  --subnet-prefixes '192.168.1.0/24'

# Create Availability Set
az vm availability-set create \
  -n vm-as \
  -l $location \
  -g $group

# Create Network Security Group (NSG)
az network nsg create \
  -g $group \
  -n vm-nsg

# Create VMs in a loop
for NUM in 1 2 3
do
  az vm create \
    -n vm-eu-0$NUM \
    -g $group \
    -l $location \
    --size Standard_B1s \
    --image Win2019Datacenter \
    --admin-username $username \
    --admin-password $password \
    --vnet-name $vnetname \
    --subnet subnet \
    --public-ip-address "" \
    --availability-set vm-as \
    --nsg vm-nsg
done

# Open port 80 for each VM
for NUM in 1 2 3
do
  az vm open-port -g $group --name vm-eu-0$NUM --port 80
done

# Install IIS on each VM using Custom Script Extension
for NUM in 1 2 3
do
  az vm extension set \
    --name CustomScriptExtension \
    --vm-name vm-eu-0$NUM \
    -g $group \
    --publisher Microsoft.Compute \
    --version 1.8 \
    --settings '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \\"C:\\inetpub\\wwwroot\\Default.htm\\" -Value \\"$($env:computername)\\""}'
done
