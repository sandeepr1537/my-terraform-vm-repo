provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "vm_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Read the VM list from the CSV file
locals {
  vmlist = csvdecode(file("${path.module}/vmlist.csv"))
}

# Loop through the VM list to create VMs
resource "azurerm_virtual_machine" "vm" {
  for_each = { for vm in local.vmlist : vm.name => vm }

  name                  = each.value.name
  location              = var.location
  resource_group_name   = azurerm_resource_group.vm_rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  vm_size               = each.value.size  # VM size comes from CSV

  storage_image_reference {
    publisher = element(split(":", each.value.image), 0)
    offer     = element(split(":", each.value.image), 1)
    sku       = element(split(":", each.value.image), 2)
    version   = element(split(":", each.value.image), 3)
  }

  storage_os_disk {
    name              = "${each.value.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = each.value.name
    admin_username = "azureuser"
    admin_password = "Password123!"  # Use secrets or environment variables in real scenarios
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Environment = "Production"
  }
}

# Network interface for the VMs
resource "azurerm_network_interface" "vm_nic" {
  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a virtual network for the VMs
resource "azurerm_virtual_network" "vm_vnet" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name
}

# Create a subnet for the VMs
resource "azurerm_subnet" "vm_subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create the host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                = var.hostpool_name
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  friendly_name       = "My Host Pool"
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
  maximum_sessions    = 10

  tags = {
    Environment = "Production"
  }
}

# Assign VMs to the host pool
resource "azurerm_virtual_desktop_application_group" "app_group" {
  name                = "${var.hostpool_name}-appgroup"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = var.location
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  type                = "Desktop"
}

# Create a workspace and link to the host pool
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  friendly_name       = "My AVD Workspace"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspace_association" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.app_group.id
}
