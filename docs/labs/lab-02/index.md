# lab-02 - configure Azure Firewall with hub-and-spoke network topology

You can implement hub-and-spoke architectures in two ways:

- Self-managed hub-and-spoke (traditional): You maintain full control over the hub virtual networks and routing configuration.
- Virtual WAN: Microsoft manages the hub virtual networks and simplifies administration through features like routing intent and routing policies.

In our labs we will use a self-managed hub-and-spoke setup, which includes the following components:

- Hub: A virtual network that serves as the central connectivity point to your on-premises network through VPN or ExpressRoute. Network security devices like Azure Firewalls is deployed in the hub virtual network as well.
- Spokes: Virtual networks that peer with the hub and host your workloads.

![lab-networking](../../assets/images/lab-02/lab-networking.png)

For our lab, we will look at the following potential traffic flow:

- Spoke-to-spoke traffic
- Spoke-to-internet traffic
- Internet-to-spoke traffic 

## Task #1 - implement spoke-to-spoke and spoke-to-internet connectivity

### Spoke-to-spoke traffic
As we learned from lab1, spokes are peered into the hub virtual network and aren't peered to each other. Virtual network peering isn't transitive. Each spoke knows how to route to the hub virtual network by default, but not to other spokes. To fix this, we need to add a User Defined Route table for each spoke subnet with a route(s) with next hop set to Azure Firewall private IP address in the hub virtual network.

In our lab, lets define the following routing rules:

- from spoke1, everything should be routed via Azure Firewall
- from spoke2, only traffic to spoke1 should be routed via Azure Firewall


### Spoke-to-internet traffic
The `0.0.0.0/0` route in the spoke1 route table also covers traffic sent to the public internet. This route overwrites the system route included in public subnets by default. 
Firewall rules for spoke-to-internet traffic flow will be configured at lab-04.

### Internet-to-spoke traffic
Internet-to-spoke traffic flow will be covered in lab-05.

![spoke-to-spoke-and-internet](../../assets/images/lab-02/udr.png)

During lab-01 we already deployed Azure Firewall in the hub virtual network. Now we need to implement User Defined Routes (UDR) that will route spoke traffic via  Azure Firewall. First, let's get the private IP address of the Azure Firewall using `az cli`.

```powershell
az network firewall show -g rg-westeurope-azfw-labs -n naf-westeurope --query "ipConfigurations[0].privateIPAddress" -o tsv
```

If you used the original script without changing it, the private IP address of Azure Firewall should be `10.9.0.4`.

Now, let's create UDR for spoke1 traffic flows. Create `spoke1-udr.bicep` file with the following content:

```bicep
param firewallPrivateIp string = '10.9.0.4'

resource spoke1Route 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'spoke1-udr'
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke1-udr'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}
```

Deploy it using `az cli`:

```powershell
# Get Azure Firewall Private IP address
$firewallIP = (az network firewall show -g rg-westeurope-azfw-labs -n naf-westeurope --query "ipConfigurations[0].privateIPAddress" -o tsv)

# Deploy UDR
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spoke1-udr.bicep --parameter firewallPrivateIp=$firewallIP
```

Now, we need to associate this UDR with spoke1 subnets. Let's assign it to the spoke1 subnet sing `az cli`:

```powershell
az network vnet subnet update --resource-group rg-westeurope-azfw-labs --vnet-name vnet-spoke1-westeurope --name subnet-workload --route-table spoke1-udr
```

Now, let's create UDR for spoke2 traffic flows. Create `spoke2-udr.bicep` file with the following content:

```bicep
param firewallPrivateIp string = '10.9.0.4'
param spoke1AddressRange string = '10.9.1.0/24'

resource spoke2Route 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'spoke2-udr'
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke2-udr'
        properties: {
          addressPrefix: spoke1AddressRange
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}
```

Deploy it using `az cli`:

```powershell
# Get Azure Firewall Private IP address
$firewallIP = (az network firewall show -g rg-westeurope-azfw-labs -n naf-westeurope --query "ipConfigurations[0].privateIPAddress" -o tsv)

# Deploy UDR
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spoke2-udr.bicep --parameter firewallPrivateIp=$firewallIP
```

Let's use Bicep to assign the UDR to the spoke2 subnet. Create `spoke2-subnet.bicep` file with the following content:

```bicep
resource udr 'Microsoft.Network/routeTables@2021-02-01' existing = {
  name: 'spoke2-udr'
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: 'vnet-spoke2-westeurope'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: 'subnet-workload'
  parent: vnet
  properties: {
    addressPrefixes: [
      '10.9.2.0/24'
    ]
    routeTable: {
      id: udr.id
    }
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}
```
Deploy it using `az cli`:

```powershell
az deployment group create --resource-group rg-westeurope-azfw-labs --template-file spoke2-subnet.bicep
```

## Task #2 - test and troubleshoot spoke-to-spoke connectivity

Now, let's test the connectivity between `vm-spoke1-westeurope` and `vm-spoke2-westeurope`. Connect to `vm-spoke1-westeurope` using Azure Bastion and ssh extensions as we did in lab-01. 

```powershell
$vmId = (az vm show --name vm-spoke1-westeurope --resource-group rg-westeurope-azfw-labs --query id --output tsv)
az network bastion ssh --name bastion-westeurope --resource-group rg-westeurope-azfw-labs --target-resource-id $vmId --auth-type password --username iac-admin
```

Once connected, try to ping `vm-spoke2-westeurope` private IP address `10.9.2.4`.

```bash
ping 10.9.2.4
```

Ping will fail because spoke-to-spoke traffic is now routed via Azure Firewall and Azure Firewall, by default, blocks all traffic. To confirm this, navigate to `Azure Firewall -> naf-westeurope -> Monitoring -> Logs ` at the portal and execute the following Kusto Query to see the blocked traffic:

```kusto
AZFWNetworkRule
| where TimeGenerated > ago(10min)
| summarize count() by SourceIp, DestinationIp, Protocol, DestinationPort, Action
```

You should see the following results

![blocked-ping](../../assets/images/lab-02/blocked-ping.png)

As you can see, ICMP traffic (aka ping) from `10.9.1.4 (vm-spoke1-westeurope)` to `10.9.2.4 (vm-spoke2-westeurope)` is being blocked (Action = `Deny`) by Azure Firewall.

> Note! There might be a delay of a few minutes before Azure Firewall logs appear in Log Analytics for querying. If you don't see logs after 5 minutes, don't waste your time and proceed to next tasks. We will get back to logs later.

