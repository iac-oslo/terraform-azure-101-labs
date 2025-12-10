param parLocation string
param hubVnetId string
param inboundSubnetId string
param outboundSubnetId string

module dnsResolver 'br/public:avm/res/network/dns-resolver:0.5.5' = {
  name: 'deploy-dns-resolver-${parLocation}'
  params: {
    name: 'dns-resolver-${parLocation}'
    virtualNetworkResourceId: hubVnetId
    inboundEndpoints: [
      {
        name: 'dns-resolver-inbound'
        subnetResourceId: inboundSubnetId
        privateIpAddress: '10.9.0.132'
        privateIpAllocationMethod: 'Static'
      }
    ]
    outboundEndpoints: [
      {
        name: 'dns-resolver-outbound'
        subnetResourceId: outboundSubnetId        
      }
    ]    
  }
}

module dnsForwardingRuleset 'br/public:avm/res/network/dns-forwarding-ruleset:0.5.3' = {
  name: 'deploy-dns-forwarding-ruleset'
  params: {
    name: 'dns-forward-ruleset-${parLocation}'
    location: parLocation    
    dnsForwardingRulesetOutboundEndpointResourceIds: [
      dnsResolver.outputs.outboundEndpointsObject[0].resourceId
    ]
    virtualNetworkLinks: [
      {
        name: 'hub-vnet'
        virtualNetworkResourceId: hubVnetId
      }
    ]
    forwardingRules: [
      {
        domainName: 'iac-labs.local.'
        forwardingRuleState: 'Enabled'
        name: 'iac-labs-local'
        targetDnsServers: [
          {
            ipAddress: '10.9.4.4' // on-prem DNS server IP
            port: 53
          }
        ]
      }      
    ] 
  }
}
