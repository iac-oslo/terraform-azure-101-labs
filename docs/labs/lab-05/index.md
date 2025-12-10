# lab-05 - Filter inbound Internet traffic with Azure Firewall DNAT rules

You can configure Azure Firewall Destination Network Address Translation (DNAT) to translate and filter inbound internet traffic to your subnets. When you configure DNAT, the NAT rule collection action is set to DNAT. Each rule in the NAT rule collection can then be used to translate your firewall's public address and port to a private IP address and port. For security reasons, it's recommended to add a specific source to allow DNAT access to the network and avoid using wildcards. 


# Task #1 - enable SSH from your home IP address to the Spoke1 VM

Create new file `inbound-dnat-rules.bicep` with the following DNAT rule content:

```bicep
param parLocation string = 'westeurope'
param parYourHomeIP string
param parFirewallPublicIP string

resource firewallPolicies 'Microsoft.Network/firewallPolicies@2024-07-01' existing = {
  name: 'nfp-${parLocation}'
}

resource spokesRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicies
  name: 'SpokesFirewallRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        name: 'spokes-nat-rc01'
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        priority: 100
        action: {
          type: 'DNAT'
        }
        rules: [
        {
            name: 'allow-ssh-to-spoke1vm'
            ruleType: 'NatRule'
            translatedAddress: '10.9.1.4'
            translatedPort: '22'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              parYourHomeIP 
            ]
            sourceIpGroups: []
            destinationAddresses: [
              parFirewallPublicIP 
            ]
            destinationPorts: [
              '22'
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
# get your home ip from https://ifconfig.me/
$yourHomeIP = (curl -s ifconfig.me)

# get firewall Public IP
$firewallPublicIP = (az network public-ip show --resource-group rg-westeurope-azfw-labs --name pip-01-naf-westeurope --query ipAddress --output tsv)

# deploy inbound-dnat-rules.bicep
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file inbound-dnat-rules.bicep --parameters parYourHomeIP=$yourHomeIP --parameters parFirewallPublicIP=$firewallPublicIP
```


```kusto
AZFWNatRule
| where TimeGenerated > ago(60min)
| summarize count() by SourceIp, DestinationIp, DestinationPort, TranslatedIp, TranslatedPort, Protocol
```

![dnat-logs](../../assets/images/lab-05/dnat-logs.png)