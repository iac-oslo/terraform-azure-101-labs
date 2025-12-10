targetScope = 'resourceGroup'

param parLocation string
param hubVnetId string

module publicIP 'br/public:avm/res/network/public-ip-address:0.9.1' = {
  name: 'deploy-public-ip'
  params: {
    name: 'pip-bastion-${parLocation}'
    location: parLocation
    skuName: 'Standard'
    availabilityZones: []
  }
}

resource resBastion 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: 'bastion-${parLocation}'
  location: parLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: false
    disableCopyPaste: false
    enableShareableLink: false
    enableKerberos: false
    enableSessionRecording: false
    ipConfigurations: [
      {
        name: 'IpConfAzureBastionSubnet'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.outputs.resourceId
          }
          subnet: {
            id: '${hubVnetId}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}
