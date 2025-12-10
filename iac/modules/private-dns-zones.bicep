param hubVNetId string

module privateDnsZoneKeyVault 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: 'deploy-keyvault-private-dns-zone'
  params: {
    name: 'privatelink.vaultcore.azure.net'    
    location: 'global'    
    virtualNetworkLinks: [
      {
        registrationEnabled: true
        virtualNetworkResourceId: hubVNetId
      }
    ]    
  }    
}
