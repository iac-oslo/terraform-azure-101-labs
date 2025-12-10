targetScope = 'subscription'
param parLocation string

import { getResourcePrefix, hubAddressRange, adminUsername, adminPassword, spoke1VNetAddressRange } from 'variables.bicep'

var resourcePrefix = getResourcePrefix(parLocation)
var resourceGroupName = 'rg-${resourcePrefix}'
module rg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'deploy-${resourceGroupName}'
  params: {
    name: resourceGroupName
    tags: {
      Environment: 'IaC'
    }
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'deploy-law'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    name: 'law-${resourcePrefix}'
    location: parLocation
  }
}

module hub 'modules/hub.bicep' = {
  name: 'deploy-hub-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    parLocation: parLocation
    parAddressRange: hubAddressRange
  }
}


module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parLocation: parLocation
    hubVnetId: hub.outputs.hubVnetId
  }
}

module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parLocation: parLocation
    hubVnetId: hub.outputs.hubVnetId
    workspaceResourceId: workspace.outputs.resourceId
  }
}

module spokes 'modules/spoke.bicep' = {
  name: 'deploy-spoke1-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parIndex: 1
    parLocation: parLocation
    parAddressRange: spoke1VNetAddressRange
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetId: hub.outputs.hubVnetId
    firewallPrivateIP: firewall.outputs.firewallPrivateIP
  }  
}

module dnsResolver 'modules/dns-resolver.bicep' = {
  name: 'deploy-dns-resolver-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parLocation: parLocation
    hubVnetId: hub.outputs.hubVnetId
    inboundSubnetId: hub.outputs.dnsResolverInboundSubnetResourceId
    outboundSubnetId: hub.outputs.dnsResolverOutboundSubnetResourceId
  }
}

module privateDnsZone 'modules/private-dns-zones.bicep' = {
  name: 'deploy-private-dns-zones-${parLocation}'
  scope: resourceGroup(resourceGroupName)
  params: {
    hubVNetId: hub.outputs.hubVnetId
  }
}

module dnsServer 'modules/dns-server.bicep' = {
  name: 'deploy-dns-server-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parLocation: parLocation
    hubVnetId: hub.outputs.hubVnetId
  }
}
