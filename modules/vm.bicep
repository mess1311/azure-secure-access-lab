// modules/vm.bicep
// A Windows Server VM with NO public IP. Reached only via Bastion.

@description('Azure region for all resources')
param location string

@description('Resource ID of the VM subnet')
param vmSubnetId string

@description('Resource ID of the Application Security Group')
param asgId string

param vmName string = 'vm-secure-lab'
param vmSize string = 'Standard_B2s'

@description('Local admin username')
param adminUsername string

@description('Local admin password')
@secure()
param adminPassword string

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vmSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          applicationSecurityGroups: [
            { id: asgId }
          ]
          // Intentionally no publicIPAddress property -> no public IP.
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmId string = vm.id
output nicPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
