terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend azurerm {
    resource_group_name = "tfbackendaa"
    storage_account_name = "aaftbackend"
    container_name = "aalabtf"
    key = "terraform.tfstate"
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks_rg" {
  name = var.resource_group_name
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}
resource "azurerm_log_analytics_workspace" "aalog_analytics_wksp" {
    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
    name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
    location            = var.log_analytics_workspace_location
    resource_group_name = azurerm_resource_group.aks_rg.name
    sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "aalog_analytics" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.aalog_analytics_wksp.location
    resource_group_name   = azurerm_resource_group.aks_rg.name
    workspace_resource_id = azurerm_log_analytics_workspace.aalog_analytics_wksp.id
    workspace_name        = azurerm_log_analytics_workspace.aalog_analytics_wksp.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
    name                = var.cluster_name
    location            = azurerm_resource_group.aks_rg.location
    resource_group_name = azurerm_resource_group.aks_rg.name
    dns_prefix          = var.dns_prefix
    oidc_issuer_enabled = true
    #api_server_authorized_ip_ranges = ""

    # key_vault_secrets_provider {
    #   secret_rotation_enabled = true
    #   secret_rotation_interval = 
    # }

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = file(var.ssh_public_key)
        }
    }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_D2_v2"
        enable_auto_scaling = true
        min_count = 1
        max_count = 3
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    network_profile {
        load_balancer_sku = "standard"
        network_plugin = "kubenet"
    }

    oms_agent {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aalog_analytics_wksp.id

    }


    tags = {
        Environment = "Development"
    }
}