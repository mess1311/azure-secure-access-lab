// modules/storage.bicep
// Storage account that is only reachable via a private endpoint.

@description('Azure region for all resources')
param location string

@description('Globally unique storage account name (3-24 lowercase letters/numbers)')
@minLength(3)
@maxLength(24)
param storageAccountName string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

output storageAccountId string = storage.id
output storageAccountName string = storage.name
