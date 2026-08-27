// modules/vnet.bicep
// Creates the VNet with 3 subnets (Firewall, Bastion, Private Endpoint).
// The VM subnet is intentionally created later (modules/routetable.bicep)
// once the Firewall's private IP is known, so it can be attached with a
// route table + NSG in one shot.

@description('Azure region for all resources')
param location string

@description('Name of the VNet')
param vnetName string = 'vnet-secure-lab'

@description('Address space for the VNet')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('AzureFirewallSubnet prefix (must be /26 or larger)')
param firewallSubnetPrefix string = '10.0.2.0/26'

@description('AzureBastionSubnet prefix (must be /26 or larger)')
param bastionSubnetPrefix string = '10.0.4.0/26'

@description('Private Endpoint subnet prefix')
param peSubnetPrefix string = '10.0.3.0/24'

var peSubnetName = 'PrivateEndpointSubnet'

resource asg 'Microsoft.Network/applicationSecurityGroups@2023-09-01' = {
  name: 'asg-vm-workload'
  location: location
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-vm-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Bastion-RDP-SSH-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: bastionSubnetPrefix
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            { id: asg.id }
          ]
          destinationPortRanges: [
            '3389'
            '22'
          ]
        }
      }
      {
        name: 'Deny-All-Other-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: peSubnetName
        properties: {
          addressPrefix: peSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetAddressPrefix string = vnetAddressPrefix
output firewallSubnetId string = '${vnet.id}/subnets/AzureFirewallSubnet'
output bastionSubnetId string = '${vnet.id}/subnets/AzureBastionSubnet'
output peSubnetId string = '${vnet.id}/subnets/${peSubnetName}'
output peSubnetName string = peSubnetName
output nsgId string = nsg.id
output asgId string = asg.id
