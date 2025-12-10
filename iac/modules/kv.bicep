param parLocation string = 'westeurope'

resource spoke1VNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'vnet-spoke1-${parLocation}'
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: 'privatelink.vaultcore.azure.net'
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: 'law-${parLocation}-dnsresolver-labs'
}

var uniqueStringSuffix = toLower(uniqueString(subscription().id, resourceGroup().id))
module vault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: 'vaultDeployment'
  params: {
    name: uniqueStringSuffix
    diagnosticSettings: [
      {
        logCategoriesAndGroups: [
          {
            category: 'AzurePolicyEvaluationDetails'
          }
          {
            category: 'AuditEvent'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'diagnostics'
        workspaceResourceId: workspace.id
      }
    ]
    enablePurgeProtection: false
    enableRbacAuthorization: false
    location: parLocation
    networkAcls: {
      bypass: 'AzureServices'
    }
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZone.id
            }
          ]
        }
        resourceGroupResourceId: resourceGroup().id
        subnetResourceId: '${spoke1VNet.id}/subnets/subnet-ple'
      }
    ]
    softDeleteRetentionInDays: 7
  }
}
