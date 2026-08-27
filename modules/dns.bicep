// modules/dns.bicep
// Private DNS zone for Storage (blob) private endpoints + a VNet link so
// records registered by the private endpoint resolve automatically.

@description('Resource ID of the VNet to link')
param vnetId string

param privateDnsZoneName string = 'privatelink.blob.core.windows.net'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneName string = privateDnsZone.name
