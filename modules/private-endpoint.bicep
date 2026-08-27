// modules/private-endpoint.bicep
// Private Endpoint for the storage account's "blob" subresource, plus the
// DNS zone group that auto-registers the A record in the private zone.

@description('Azure region for all resources')
param location string

@description('Resource ID of the subnet the private endpoint NIC lands in')
param peSubnetId string

@description('Resource ID of the storage account')
param storageAccountId string

@description('Resource ID of the privatelink.blob.core.windows.net DNS zone')
param privateDnsZoneId string

param privateEndpointName string = 'pe-storage-blob'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-conn'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob-config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
