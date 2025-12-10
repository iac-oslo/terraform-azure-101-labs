# lab-01 - provisioning of lab resources

As always, we need to provision lab environment before we start working on the labs. To make sure you have all resource providers required by lab resources, run the following commands.  

```powershell
# Make sure that all Resource Providers are registered
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Compute
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
az provider register -n Microsoft.Compute
```

Install required `az cli` extensions

```powershell
# install bastion extension
az extension add -n bastion

# install ssh extension
az extension add -n ssh

# install azure-firewall extension
az extension add -n azure-firewall
```

## Task #1 - Provision lab environment

Let's clone lab repo and deploy the environment.  

```powershell
# Clone the repository to your local machine:
git clone https://github.com/iac-oslo/azure-firewall-labs.git

# Navigate to iac folder
cd .\azure-firewall-labs\iac

# Deploy the environment
./deploy.ps1
```

Estimated deployment time is approx. 10-15 min. 

The following resources will be deployed in your subscription under `rg-westeurope-azfw-labs` resource group:

| Resource name | Type | 
|---------------|------|
| law-westeurope-azfw-labs | Log Analytics Workspace |
| nfp-westeurope | Firewall Policy (Basic sku) |
| naf-westeurope | Azure Firewall (Basic sku) |
| pip-01-naf-westeurope | Public IP used by Azure Firewall |
| pip-02-naf-westeurope | Public IP used by Azure Firewall |
| naf-westeurope-mip | Azure Firewall Management IP Configuration |
| bastion-westeurope | Azure Bastion Host (Standard)|
| pip-bastion-westeurope | Public IP used by Azure Bastion Host |
| vnet-hub-westeurope | Hub Virtual Network |
| vnet-spoke1-westeurope | Spoke1 Virtual Network |
| vnet-spoke2-westeurope | Spoke2 Virtual Network |
| vm-hub-westeurope | Hub Virtual Machine |
| vm-spoke1-westeurope | Spoke1 Virtual Machine |
| vm-spoke2-westeurope | Spoke2 Virtual Machine |

![lab-networking](../../assets/images/lab-01/infra.png)

Provision script is implemented as Bicep template with use of [Azure Verified modules](https://azure.github.io/Azure-Verified-Modules/indexes/bicep/bicep-resource-modules/) for most of the resources except Azure Bastion Host.

`10.9.0.0/16` address pool is used for lab networking and the following IP ranges are used for virtual networks:

| Virtual Network | IP Range |
|------------------|----------|
| vnet-hub-westeurope | 10.9.0.0/24 |
| vnet-spoke1-westeurope | 10.9.1.0/24 |
| vnet-spoke2-westeurope | 10.9.2.0/24 |


`vnet-hub-westeurope` contains four subnets:

| Subnet Name | IP Range |
|-------------|----------|
| AzureFirewallSubnet    | 10.9.0.0/26 |
| AzureBastionSubnet    | 10.9.0.64/26 |
| AzureFirewallManagementSubnet    | 10.9.0.192/26 |
| subnet-workload    | 10.9.0.128/26 |

### Allocated IP addresses

If you used the original script without changing it, most likely resources created under your subscription will be allocated with the same private IP addresses. Use scripts below to verify the allocated IP addresses. If they are different, you need to use your own IPs further in the labs.

#### Azure Firewall Private IP

Get private IP of Azure Firewall.

```powershell
az network firewall show -g rg-westeurope-azfw-labs -n naf-westeurope --query ipConfigurations[0].privateIPAddress -o tsv
```

Azure Firewall private IP is `10.9.0.4`

#### Virtual Machine IP addresses:

```powershell
# get private ip for vm-hub-westeurope
az vm show -d -g rg-westeurope-azfw-labs -n vm-hub-westeurope --query privateIps -o tsv

# get private ip for vm-spoke1-westeurope
az vm show -d -g rg-westeurope-azfw-labs -n vm-spoke1-westeurope --query privateIps -o tsv

# get private ip for vm-spoke2-westeurope
az vm show -d -g rg-westeurope-azfw-labs -n vm-spoke2-westeurope --query privateIps -o tsv

```

| VM | IP Range |
|------------------|----------|
| vm-hub-westeurope | 10.9.0.132 |
| vm-spoke1-westeurope | 10.9.1.4 |
| vm-spoke2-westeurope | 10.9.2.4 |

Connect to `vm-spoke1-westeurope` using `az cli` Bastion and ssh extensions. Use `iac-admin` `fooBar123!` as a username and password to login. 

## Task #2 - Configure Diagnostic settings for Azure Firewall

To be able to monitor Azure Firewall logs and metrics, we need to configure diagnostic settings for it. There are several destinations you can send diagnostic logs to, but in this lab we will use Log Analytics workspace. 

Navigate to the `naf-westeurope` Azure Firewall resource in the portal, select `Monitoring -> Diagnostic settings` blade and click `+ Add diagnostic setting`.

![diag-settings](../../assets/images/lab-01/diagnostic-settings-1.png)

Fill in the following details:

| Setting name | Value |
|--------------|---------------------|
| Diagnostic setting name  | diagnostic |
| Send to Log Analytics workspace | Checked |
| Subscription | Your subscription |   
| Log Analytics workspace | law-westeurope-azfw-labs |
| Destination table | Select `Resource specific` |
| Categories | Check `Azure Firewall Network Rule`, `Azure Firewall Application Rule` and `Azure Firewall Nat Rule`  |

![diag-settings-2](../../assets/images/lab-01/diagnostic-settings-2.png)

Click Save.

Destination table `Resource specific` means that logs and metrics are written to individual tables for each category of the resource. We selected `Azure Firewall Network Rule`, `Azure Firewall Application Rule` and `Azure Firewall Nat Rule` categories, so the following tables will be created in Log Analytics workspace:

- `AZFWNetworkRule`
- `AZFWApplicationRule`
- `AZFWNatRule`


## Task #3 - Connect to vm-hub-westeurope using Azure Bastion and SSH

Get `vm-hub-westeurope` VM resource id and SSH into it via bastion host.

```powershell
$vmId = (az vm show --name vm-hub-westeurope --resource-group rg-westeurope-azfw-labs --query id --output tsv)
az network bastion ssh --name bastion-westeurope --resource-group rg-westeurope-azfw-labs --target-resource-id $vmId --auth-type password --username iac-admin
```

From hub VM terminal session, check that you can both ping and ssh to `vm-spoke1-westeurope`.

```powershell
ping 10.9.1.4
ssh iac-admin@10.9.1.4
```

## Task #4 - Connect to vm-spoke1-westeurope using Azure Bastion and SSH

Get `vm-spoke1-westeurope` VM resource id and SSH into it via bastion host.

```powershell
$vmId = (az vm show --name vm-spoke1-westeurope --resource-group rg-westeurope-azfw-labs --query id --output tsv)
az network bastion ssh --name bastion-westeurope --resource-group rg-westeurope-azfw-labs --target-resource-id $vmId --auth-type password --username iac-admin
```

From spoke1 VM, check that you can both ping and ssh to `vm-hub-westeurope`.

```powershell
ping 10.9.0.132
ssh iac-admin@10.9.0.132
```

Note, that there is no connectivity between spoke1 and spoke2 VMs at this point. 

```powershell
ping 10.9.2.4
ssh iac-admin@10.9.2.4
```

This is logical, because there is no peering between spoke1 and spoke2 VNets. We will address this in the next lab.