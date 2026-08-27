// modules/bastion.bicep
// Azure Bastion so the VM never needs a public IP for RDP/SSH.

@description('Azure region for all resources')
param location string

@description('Resource ID of AzureBastionSubnet')
param bastionSubnetId string

param bastionName string = 'bas-secure-lab'
param bastionPipName string = 'pip-bastion-secure-lab'

resource pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastion.id
