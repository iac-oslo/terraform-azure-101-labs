targetScope = 'resourceGroup'

param parLocation string
param hubVnetId string

var varVNetName = 'vnet-dnsserver-${parLocation}'

import { dnsServerVNetAddressRange, dnsServerIpAddress, adminUsername, adminPassword } from '../variables.bicep'

module modVNet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${varVNetName}'
  params: {
    addressPrefixes: [
      dnsServerVNetAddressRange
    ]
    name: varVNetName
    location: parLocation
    subnets: [
      {
        name: 'subnet-dnsserver'
        addressPrefixes: [
          dnsServerVNetAddressRange
        ]
      }            
    ]
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'hub-to-dns-server'
        remoteVirtualNetworkResourceId: hubVnetId
        useRemoteGateways: false
      }
    ]  
    enableTelemetry: false
  }
}

module modHubVM 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: 'deploy-dnsserver-vm-${parLocation}'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-dnsserver-${parLocation}'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: modVNet.outputs.subnetResourceIds[0]
            privateIPAddress: dnsServerIpAddress
          }
        ]
        nicSuffix: '-nic-01'
        enableAcceleratedNetworking: false
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'StandardSSD_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_D2ds_v6'
    availabilityZone: -1
    location: parLocation
    enableTelemetry: false
  }
}
