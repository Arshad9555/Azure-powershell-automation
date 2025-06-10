# -----------------------------
# PowerShell Script: create-vm.ps1
# Purpose: Create a VM in Azure using Ubuntu 22.04 (Gen 2) in East US
# -----------------------------

# Variables
$resourceGroup = "RG-Automation"
$location = "eastus"
$vmName = "mypsvm"
$vmSize = "Standard_B1s"
$subnetName = "$vmName-subnet"
$vnetName = "$vmName-vnet"
$nsgName = "$vmName-nsg"
$ipName = "$vmName-ip"
$nicName = "$vmName-nic"

# Prompt for VM admin credentials
$cred = Get-Credential -Message "Enter VM admin credentials"

# Create Resource Group (only if it doesn't already exist)
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location
}

# Create subnet + VNet
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24"
$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup `
    -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet

# Create NSG
$nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup -Location $location

# Create Public IP (Static is required for Standard SKU)
$publicIP = New-AzPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroup `
    -Location $location -Sku Standard -AllocationMethod Static

# Create NIC
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup `
    -Location $location -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $publicIP.Id -NetworkSecurityGroupId $nsg.Id

# Configure the VM
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred |
    Set-AzVMSourceImage `
        -PublisherName "Canonical" `
        -Offer "0001-com-ubuntu-server-jammy" `
        -Skus "22_04-lts-gen2" `
        -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic.Id

# Create the VM
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig
