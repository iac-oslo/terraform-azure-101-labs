targetScope = 'resourceGroup'

param parLocation string
param parAddressRange string

var varVNetName = 'vnet-hub-${parLocation}'

module modVNet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${varVNetName}'
  params: {
    addressPrefixes: [
      parAddressRange
    ]
    name: varVNetName
    location: parLocation
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefixes: [cidrSubnet(parAddressRange, 26, 0)]
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefixes: [cidrSubnet(parAddressRange, 26, 1)]
      }
      {
        name: 'subnet-resolver-inbound'
        addressPrefixes: [cidrSubnet(cidrSubnet(parAddressRange, 26, 2), 28, 0)] 
        delegation: 'Microsoft.Network/dnsResolvers' 
      }
      {
        name: 'subnet-resolver-outbound'
        addressPrefixes: [cidrSubnet(cidrSubnet(parAddressRange, 26, 2), 28, 1)] 
        delegation: 'Microsoft.Network/dnsResolvers' 
      }
      {
        name: 'subnet-dnsserver'
        addressPrefixes: [cidrSubnet(cidrSubnet(parAddressRange, 26, 2), 28, 3)] 
      }            
    ]
    enableTelemetry: false
  }
}

output hubVnetId string = modVNet.outputs.resourceId
output dnsServerSubnetResourceId string = modVNet.outputs.subnetResourceIds[4]
output dnsResolverInboundSubnetResourceId string = modVNet.outputs.subnetResourceIds[2]
output dnsResolverOutboundSubnetResourceId string = modVNet.outputs.subnetResourceIds[3]
