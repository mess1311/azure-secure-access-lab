# Azure Secure Access Lab 

This lab implements a production‑style secure network environment in Azure. The goal is to ensure all workloads communicate privately, securely, and through controlled paths.

```
                         Internet
                            │
                    ┌───────┴────────┐
                    │  Azure Firewall │◄── forced tunneling (UDR)
                    │  (public IP)    │
                    └───────┬────────┘
                            │
   ┌────────────────────────────────────────────┐
   │                    VNet 10.0.0.0/16          │
   │                                              │
   │  snet-vm 10.0.1.0/24        AzureFirewallSubnet 10.0.2.0/26
   │  ┌─────────────┐            ┌──────────────┐
   │  │  VM (no      │◄──RDP/SSH─│ AzureBastion  │◄── you (browser/portal)
   │  │  public IP)  │            │ Subnet        │
   │  └──────┬──────┘            └──────────────┘
   │         │ NSG + ASG
   │  PrivateEndpointSubnet 10.0.3.0/24
   │  ┌───────────────┐     ┌─────────────────────┐
   │  │ Private        │────▶│ Storage Account      │
   │  │ Endpoint (blob)│     │ (public access: off) │
   │  └───────────────┘     └─────────────────────┘
   │         ▲ resolved via
   │  Private DNS zone: privatelink.blob.core.windows.net
   └────────────────────────────────────────────┘
```

Key properties: the VM has no public IP; all its outbound traffic is
forced through Azure Firewall via a route table; the storage account has
public network access disabled and is only reachable through the private
endpoint; Bastion is the only way in for RDP/SSH.

---

## Project structure
```
azure-secure-access-lab/
├── main.bicep
├── main.parameters.json
└── modules/
    ├── vnet.bicep             # VNet, 3 subnets, NSG, ASG
    ├── firewall.bicep         # Firewall Policy + rules, public IP, Firewall
    ├── routetable.bicep       # UDR + VM subnet (forced tunneling)
    ├── storage.bicep          # Storage account, public access disabled
    ├── dns.bicep               # Private DNS zone + VNet link
    ├── private-endpoint.bicep # Private Endpoint for blob + DNS zone group
    ├── bastion.bicep           # Bastion public IP + host
    └── vm.bicep                 # NIC (no public IP) + VM
```


## Deployement instructions:

Validate the template compiles cleanly:

```bash
az bicep build --file main.bicep
```

Create a resource group:

```bash
az group create --name rg-secure-access-lab --location eastus
```

Edit `main.parameters.json`:
- give `storageAccountName` a globally-unique lowercase value (3–24
  chars, letters/numbers only)
- set a strong `vmAdminPassword` (12+ chars, upper/lower/number/symbol)

Then deploy (this takes **20–35 minutes**, mostly for Azure Firewall and
Bastion):

```bash
az deployment group create \
  --resource-group rg-secure-access-lab \
  --template-file main.bicep \
  --parameters main.parameters.json
```

Watch progress:

```bash
az deployment group list \
  --resource-group rg-secure-access-lab \
  --output table
```


## Validate the architecture actually works

1. **VM has no public IP**: in the portal, open the VM → Networking →
   confirm there's no public IP listed. `az vm list-ip-addresses
   --resource-group rg-secure-access-lab -o table` should show only a
   private IP.
2. **Bastion is the only way in**: Portal → your VM → Connect → Bastion →
   sign in with the admin credentials. RDP/SSH directly to the VM's
   private IP from your laptop should simply fail (no route to it).
3. **Forced tunneling works**: from inside the VM (via Bastion), run
   `curl -s ifconfig.me` (or `Invoke-WebRequest` on Windows) — the
   returned public IP should match the **Firewall's** public IP, not a
   random Azure egress IP, confirming outbound traffic is going through
   the firewall.
4. **Storage is private-only**: try `az storage account show
   --name <name> --query publicNetworkAccess` — should say `Disabled`.
   From inside the VM, `nslookup <account>.blob.core.windows.net` should
   resolve to a `10.0.3.x` private IP, not a public Azure Storage IP.
5. **Firewall logs**: enable diagnostic settings on the firewall (Log
   Analytics) to see allowed/denied traffic, and confirm your
   application rules are being hit as expected.







