targetScope = 'resourceGroup'

param parLocation string
param parIndex int
param parAddressRange string
param adminUsername string
@secure()
param adminPassword string
param hubVnetId string
param firewallPrivateIP string

var varVNetName = 'vnet-spoke${parIndex}-${parLocation}'

resource spoke1Route 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'spoke1-udr'
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke-udr'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
    ]
  }
}

module modVNet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${varVNetName}-${parIndex}'
  params: {
    addressPrefixes: [
      parAddressRange
    ]
    name: varVNetName
    location: parLocation
    subnets: [
      {
        addressPrefixes: [cidrSubnet(parAddressRange, 25, 0)]
        name: 'subnet-workload'
        routeTableResourceId: spoke1Route.id
      }
      {
        addressPrefixes: [cidrSubnet(parAddressRange, 25, 1)]
        name: 'subnet-ple'
        routeTableResourceId: spoke1Route.id
      }
    ]
    dnsServers: [
      firewallPrivateIP
    ]
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'hub-to-spoke${parIndex}'
        remoteVirtualNetworkResourceId: hubVnetId
        useRemoteGateways: false
      }
    ]    
    enableTelemetry: false
  }
}

module modVirtualMachine 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: 'deploy-spoke${parIndex}-vm-${parLocation}'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-spoke${parIndex}-${parLocation}'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: modVNet.outputs.subnetResourceIds[0]
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
        storageAccountType: 'Standard_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_B1s'
    availabilityZone: -1
    location: parLocation
    enableTelemetry: false
  }
}

output spokeVNetId string = modVNet.outputs.resourceId
