// main.bicep
// Orchestrates the full secure Azure network lab:
// VNet -> Firewall -> Route Table/VM Subnet -> Storage -> Private DNS ->
// Private Endpoint -> Bastion -> VM

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Globally unique storage account name (3-24 lowercase letters/numbers)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Local admin username for the VM')
param vmAdminUsername string

@description('Local admin password for the VM')
@secure()
param vmAdminPassword string

// 1. Network foundation: VNet + Firewall/Bastion/PE subnets + NSG + ASG
module network 'modules/vnet.bicep' = {
  name: 'deploy-network'
  params: {
    location: location
  }
}

// 2. Azure Firewall, deployed into AzureFirewallSubnet
module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    firewallSubnetId: network.outputs.firewallSubnetId
    vnetAddressPrefix: network.outputs.vnetAddressPrefix
  }
}

// 3. UDR pointing at the firewall + the VM subnet that uses it
module routing 'modules/routetable.bicep' = {
  name: 'deploy-routing'
  params: {
    location: location
    vnetName: network.outputs.vnetName
    firewallPrivateIp: firewall.outputs.firewallPrivateIp
    nsgId: network.outputs.nsgId
  }
}

// 4. Storage account, no public network access
module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

// 5. Private DNS zone for blob storage, linked to the VNet
module dns 'modules/dns.bicep' = {
  name: 'deploy-dns'
  params: {
    vnetId: network.outputs.vnetId
  }
}

// 6. Private Endpoint connecting storage to PrivateEndpointSubnet
module privateEndpoint 'modules/private-endpoint.bicep' = {
  name: 'deploy-private-endpoint'
  params: {
    location: location
    peSubnetId: network.outputs.peSubnetId
    storageAccountId: storage.outputs.storageAccountId
    privateDnsZoneId: dns.outputs.privateDnsZoneId
  }
}

// 7. Azure Bastion for secure RDP/SSH access
module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  params: {
    location: location
    bastionSubnetId: network.outputs.bastionSubnetId
  }
}

// 8. The VM itself - no public IP, lives in the routed VM subnet
module vm 'modules/vm.bicep' = {
  name: 'deploy-vm'
  params: {
    location: location
    vmSubnetId: routing.outputs.vmSubnetId
    asgId: network.outputs.asgId
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
  }
}

output vnetName string = network.outputs.vnetName
output firewallPublicIp string = firewall.outputs.firewallPublicIp
output storageAccountName string = storage.outputs.storageAccountName
output vmPrivateIp string = vm.outputs.nicPrivateIp
