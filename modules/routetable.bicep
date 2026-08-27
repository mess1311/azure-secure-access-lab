// modules/routetable.bicep
// Creates the User Defined Route (0.0.0.0/0 -> Azure Firewall) and the
// VM subnet itself, attaching both the route table and the NSG. Doing
// this in one module avoids two resources fighting over the same VNet.

@description('Azure region for all resources')
param location string

@description('Name of the existing VNet (created in modules/vnet.bicep)')
param vnetName string

@description('Address prefix for the new VM subnet')
param vmSubnetPrefix string = '10.0.1.0/24'

@description('Private IP address of the Azure Firewall (next hop)')
param firewallPrivateIp string

@description('Resource ID of the NSG to attach to the VM subnet')
param nsgId string

param routeTableName string = 'rt-vm-subnet'
param vmSubnetName string = 'snet-vm'

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: vmSubnetName
  properties: {
    addressPrefix: vmSubnetPrefix
    networkSecurityGroup: {
      id: nsgId
    }
    routeTable: {
      id: routeTable.id
    }
  }
}

output vmSubnetId string = vmSubnet.id
output routeTableId string = routeTable.id
