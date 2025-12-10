# lab-06 - Mitigating SNAT port exhaustion (WIP)


# Task #1 - allow outbound traffic to everything from spoke1 VNet

For simplicity, we will allow outbound traffic to everything from spoke VNets. In production, you should never do it and always limit outbound traffic to only required destinations.


Create `spokes-outbound-rules.bicep` file with the following content:

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
            name: 'allow-outbound-to-star'
            ruleType: 'ApplicationRule'
            description: 'Allow HTTP/HTTPS to all'
            sourceAddresses: [
              '10.9.1.0/24'
              '10.9.2.0/24'
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
              '*'
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
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spokes-outbound-rules.bicep
```

# Task #2 - execute stress test to simulate SNAT port exhaustion

Connect to `vm-spoke1-westeurope` using SSH and execute the following command to simulate SNAT port exhaustion:

```powershell
$vmId = (az vm show --name vm-spoke1-westeurope --resource-group rg-westeurope-azfw-labs --query id --output tsv)
az network bastion ssh --name bastion-westeurope --resource-group rg-westeurope-azfw-labs --target-resource-id $vmId --auth-type password --username iac-admin
```

Download k6 script:

```bash
wget https://raw.githubusercontent.com/iac-oslo/azure-firewall-labs/refs/heads/main/iac/scripts/simulate-snat.js
```

Execute the stress test:

```bash
k6 run simulate-snat.js
```

The script will run for 5 minutes. While we are waiting, let's check the SNAT port usage in Azure Firewall metrics.
Open Azure Portal, navigate to Azure Firewall `azfw-westeurope` and click on `Metrics` blade. Select `SNAT Port Utilization` metric and set the time range to `last 30 min` at Local time. You should see the SNAT port usage increasing as the stress test is running.

![Add second public IP](../../assets/images/lab-06/metrics.png)

# Task #3 - add second public IP to Azure Firewall

To mitigate SNAT port exhaustion, we will add a second public IP address to Azure Firewall. Navigate to Azure Firewall `azfw-westeurope` in Azure Portal and click on `IP configurations` blade. Click on `+ Add` button to add `pip-02-naf-westeurope` Public IP.

![Add second public IP](../../assets/images/lab-06/add-second-ip.png)

When new IP is added, re-run the stress test. While running observe the SNAT port usage in Azure Firewall metrics. You should see that the SNAT port usage is now lower as the traffic is distributed across two public IP addresses.

![Add second public IP](../../assets/images/lab-06/compare-metrics.png)