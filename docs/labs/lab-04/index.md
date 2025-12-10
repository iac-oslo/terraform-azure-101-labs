# lab-04 - configure Azure Firewall Application Rules to allow spoke-to-internet connectivity

Azure Firewall blocks all outbound traffic by default. Let's confirm this by trying to access `ifconfig.me` resource from `vm-spoke1-westeurope` using `curl` command:

```bash
curl ifconfig.me
```

You will get the following error message `Action: Deny. Reason: No rule matched. Proceeding with default action.`

Check the Azure Firewall Application Logs to see the blocked traffic. 

```kusto
AZFWApplicationRule
| where TimeGenerated > ago(10min)
| summarize count() by SourceIp, Fqdn, Protocol, DestinationPort, Action
```

![blocked-curl](../../assets/images/lab-04/apprules-deny.png)

To allow traffic to the internet, we need to create Application rules specifying what kind of traffic is allowed.

# Task #1 - create Application Rules to allow access to `ifconfig.me` from spoke1 VNet

Create `spoke-app-rules.bicep` file with the following content:

```bicep
param parLocation string = 'westeurope'

resource firewallPolicies 'Microsoft.Network/firewallPolicies@2024-07-01' existing = {
  name: 'nfp-${parLocation}'
}

resource spokesRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicies
  name: 'SpokesFirewallApplicationRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'spokes-app-rc01'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-outbound-to-ifconfig-me'
            ruleType: 'ApplicationRule'
            description: 'Allow HTTP/HTTPS to ifconfig.me'
            sourceAddresses: [
              '10.9.1.0/24'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              'ifconfig.me'
            ]
          }
        ]
      }      
    ]
  }
}
```

Deploy it using `az cli`:

```powershell
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spoke-app-rules.bicep
```

When deployed, get back to your spoke1 VM terminal session and try to access `ifconfig.me` site again.

```bash
# Use HTTP
curl ifconfig.me

#Use HTTPS
curl https://ifconfig.me
```

This time you should get public IP address of the Azure Firewall, because all outbound traffic from spokes is now routed via Azure Firewall.

Check the Azure Firewall Application Logs to see the allowed traffic. 

```kusto
AZFWApplicationRule
| where TimeGenerated > ago(10min)
| summarize count() by SourceIp, Fqdn, Protocol, DestinationPort, Action
```

![allowed-curl](../../assets/images/lab-04/apprules-allow.png)
