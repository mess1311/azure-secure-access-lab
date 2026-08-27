// modules/firewall.bicep
// Deploys a Firewall Policy (with one network + one application rule
// collection), a Standard public IP, and Azure Firewall itself.

@description('Azure region for all resources')
param location string

@description('Resource ID of AzureFirewallSubnet')
param firewallSubnetId string

@description('Address space of the VNet - used to scope the "allow internal" rule')
param vnetAddressPrefix string

param firewallName string = 'afw-secure-lab'
param firewallPolicyName string = 'afwp-secure-lab'
param firewallPipName string = 'pip-afw-secure-lab'

resource pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: firewallPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource policy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: policy
  name: 'DefaultRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowNetworkOutbound'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'Allow-DNS'
            ipProtocols: [
              'UDP'
              'TCP'
            ]
            sourceAddresses: [
              vnetAddressPrefix
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '53'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'Allow-NTP'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              vnetAddressPrefix
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowApplicationOutbound'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'Allow-WindowsUpdate-and-Core-Services'
            protocols: [
              { protocolType: 'Https', port: 443 }
              { protocolType: 'Http', port: 80 }
            ]
            sourceAddresses: [
              vnetAddressPrefix
            ]
            targetFqdns: [
              '*.windowsupdate.com'
              '*.update.microsoft.com'
              'download.windowsupdate.com'
              'ctldl.windowsupdate.com'
              '*.azure.com'
              '*.microsoft.com'
              '*.blob.core.windows.net'
            ]
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: policy.id
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
  dependsOn: [
    ruleCollectionGroup
  ]
}

output firewallId string = firewall.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = pip.properties.ipAddress
