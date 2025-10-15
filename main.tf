# 1. Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-storage"
  location = "Central India"
}

# 2. Create Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "arundemostorageacct"   # must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "dev"
  }
}

# 3. Create Blob Container
resource "azurerm_storage_container" "container" {
  name                  = "terraformstate"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}