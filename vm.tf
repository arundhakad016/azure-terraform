# 1. Create Resource Group
resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.rg_location
}

# 2. Create Storage Account
# resource "azurerm_storage_account" "storage" {
#   name                     = "arundemostorageacct"   # must be globally unique
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = azurerm_resource_group.rg.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"

#   tags = {
#     environment = "dev"
#   }
# }

# 3. Create Blob Container
# resource "azurerm_storage_container" "container" {
#   name                  = "terraformstate"
#   storage_account_name  = azurerm_storage_account.storage.name
#   container_access_type = "private"
# }


## Creating VNET with address space, rg and location
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

## Creating subnet with name, rg, vnet, adress prefixes
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# -------------------------
# Network Security Group (SSH-only)
# -------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}nsg-demo"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# -------------------------
# Public IP
# -------------------------
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

## Creating network interfaces with name, location and rg
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

#----------------------------
# NIC and NSG Association
#----------------------------
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -------------------------
# Linux Virtual Machine
# -------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = tomap({
    name1 = "demo-vm-1"
    name2 = "demo-vm-2"
  })
  name                = each.value
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = var.vm_size
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.main.id]

  # SSH authentication (no passwords)
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./id_rsa.pub") # must exist on your system
  }

  disable_password_authentication = true

  os_disk {
    name                 = "demo-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name = "demo-vm"

  tags = {
    environment = "staging"
    owner       = "devops"
  }
}