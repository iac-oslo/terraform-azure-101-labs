targetScope = 'resourceGroup'

param parLocation string
param hubVnetId string
param workspaceResourceId string

import { dnsResolverIpAddress } from '../variables.bicep'

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.1' = {
  name: 'firewallPolicyDeployment'
  params: {
    name: 'nfp-${parLocation}'
    tier: 'Standard'
    threatIntelMode: 'Alert'
    enableProxy: true    
    // servers: [
    //   dnsResolverIpAddress
    // ]
  }
}

var nafName = 'naf-${parLocation}'
module azureFirewall 'br/public:avm/res/network/azure-firewall:0.8.0' = {
  name: 'deploy-azure-firewall'
  params: {
    name: nafName
    azureSkuTier: 'Standard'
    location: parLocation
    virtualNetworkResourceId: hubVnetId
    firewallPolicyId: firewallPolicy.outputs.resourceId   
    enableForcedTunneling: false    
    publicIPAddressObject: {
      name: 'pip-01-${nafName}'
      publicIPAllocationMethod: 'Static'
      skuName: 'Standard'
      skuTier: 'Regional'
    }    
    diagnosticSettings: [
      {
        name: 'diagnostics'
        workspaceResourceId: workspaceResourceId
        logAnalyticsDestinationType: 'Dedicated'
      }
    ]
  }
}

output firewallPrivateIP string = azureFirewall.outputs.privateIp 
