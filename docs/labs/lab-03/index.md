# lab-03 - configure Azure Firewall Network Rules to allow spoke-to-spoke connectivity

To allow traffic between spokes, we need to create an Azure Firewall Network rules specifying what kind of traffic is allowed. 

Let's implement the following rules:
- Allow ICMP (ping) traffic between spokes
- Allow SSH (TCP:22) from `vm-spoke1-westeurope` to `vm-spoke2-westeurope`

## Task #1 - create Network Rule to allow ICMP (ping) traffic between spokes

Create `spokes-network-rules.bicep` file with the following content:

```bicep
param parLocation string = 'westeurope'

resource firewallPolicies 'Microsoft.Network/firewallPolicies@2024-07-01' existing = {
  name: 'nfp-${parLocation}'
}

var spokeIPs = [
      '10.9.2.0/24'
      '10.9.1.0/24'
    ]

resource spokesRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicies
  name: 'SpokesFirewallNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'spokes-net-rc01'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
        {
            name: 'allow-ICMP-between-spokes'
            ruleType: 'NetworkRule'
            description: 'Allow ping between spokes'
            sourceAddresses: spokeIPs
            ipProtocols: [
              'ICMP'
            ]
            destinationPorts: [
                '*'
            ]
            destinationAddresses: spokeIPs
          }          
        ]
      }                      
    ]
  }
}
```

This script creates a rule collection group `spokes-net-rc01` with network rule `allow-ICMP-between-spokes` that allows ICMP traffic between the two spokes: `10.9.1.0/24` and `10.9.2.0/24`.

Deploy it using `az cli`:

```powershell
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spokes-network-rules.bicep
```

When deployed, get back to your spoke1 VM terminal session and try to ping the spoke2 VM again.

This time ping should be successful.

Check the Azure Firewall logs to see that traffic is allowed now. Again, it might take some minutes for the logs to appear.

```kusto
AZFWNetworkRule
| where TimeGenerated > ago(10min)
| summarize count() by SourceIp, DestinationIp, Protocol, DestinationPort, Action
```

![allowed-ping](../../assets/images/lab-03/allowed-ping.png)

## Task #2 - create Network Rule to allow SSH from spoke1 VM to spoke 2 VM

As we learned, by default, Azure Firewall blocks all traffic. So, if you try to ssh from `vm-spoke1-westeurope` to `vm-spoke2-westeurope`, it will fail. Let's create a network rule to allow SSH traffic from `vm-spoke1-westeurope` to `vm-spoke2-westeurope`.

Update `spokes-network-rules.bicep` file and add new Network rule:

```bicep
param parLocation string = 'westeurope'

resource firewallPolicies 'Microsoft.Network/firewallPolicies@2024-07-01' existing = {
  name: 'nfp-${parLocation}'
}

var spokeIPs = [
      '10.9.2.0/24'
      '10.9.1.0/24'
    ]

resource spokesRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicies
  name: 'SpokesFirewallNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'spokes-net-rc01'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-ICMP-between-spokes'
            ruleType: 'NetworkRule'
            description: 'Allow ping between spokes'
            sourceAddresses: spokeIPs
            ipProtocols: [
              'ICMP'
            ]
            destinationPorts: [
                '*'
            ]
            destinationAddresses: spokeIPs
          }          
          { 
            name: 'allow-ssh-from-spoke1-vm-to-spoke2-vm'
            ruleType: 'NetworkRule'
            description: 'Allow SSH from vm-spoke1-westeurope to vm-spoke2-westeurope'
            sourceAddresses: [
              '10.9.1.4'      // vm-spoke1-westeurope
            ]
            ipProtocols: [
              'TCP'
            ]
            destinationPorts: [
              '22'
            ]
            destinationAddresses: [
              '10.9.2.4'    // vm-spoke2-westeurope
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
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spokes-network-rules.bicep
```

When deployed, get back to your spoke1 VM terminal session and try to ssh to the spoke2 VM. Use `fooBar123!` as the password.

```bash
ssh iac-admin@10.9.2.4
```

You should be able to ssh successfully.

Check the Azure Firewall logs to see the allowed SSH traffic.

```kusto
AZFWNetworkRule
| where TimeGenerated > ago(10min)
| where ipv4_is_in_range(SourceIp, '10.9.1.0/24')
| summarize count() by SourceIp, DestinationIp, Protocol, DestinationPort, Action
```

> Note: You can use `ipv4_is_in_range` function to filter traffic from a specific subnet.

![allowed-ssh](../../assets/images/lab-03/allowed-ssh.png)