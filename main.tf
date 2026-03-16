data "azurerm_resource_group" "app_rg" {
  name = "rg-aca-${var.env}"
}

# ------------------------------------------------------------------
# [분기 A] 기존 환경 사용 (create_environment == false)
# ------------------------------------------------------------------
data "azurerm_container_app_environment" "existing_cae" {
  count               = var.create_environment ? 0 : 1
  name                = var.cae_name
  resource_group_name = var.cae_rg_name
}

# ------------------------------------------------------------------
# [분기 B] 새로운 환경 생성 (create_environment == true)
# ------------------------------------------------------------------
data "azurerm_log_analytics_workspace" "law" {
  count               = var.create_environment ? 1 : 0
  name                = "law-krc-${var.env}-common" 
  resource_group_name = "rg-krc-${var.env}-common"
}

resource "azurerm_container_app_environment" "new_cae" {
  count                      = var.create_environment ? 1 : 0
  name                       = var.cae_name
  location                   = data.azurerm_resource_group.app_rg.location
  resource_group_name        = var.cae_rg_name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law[0].id
}

locals {
  final_cae_id = var.create_environment ? azurerm_container_app_environment.new_cae[0].id : data.azurerm_container_app_environment.existing_cae[0].id
}

# ------------------------------------------------------------------
# [배포] Container App
# ------------------------------------------------------------------
resource "azurerm_container_app" "app" {
  name                         = var.app_name
  container_app_environment_id = local.final_cae_id
  resource_group_name          = data.azurerm_resource_group.app_rg.name
  revision_mode                = "Single"

  # [수정 1] 관리 ID 부여: 앱이 ACR에 접근할 수 있도록 신분증(UAMI)을 달아줍니다.
  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_resource_id]
  }

  # [수정 2] ACR 레지스트리 설정: 어떤 ID로 ACR에 로그인할지 명시합니다.
  registry {
    server   = var.acr_server
    identity = var.uami_resource_id
  }

  template {
    container {
      name   = var.app_name
      image  = var.image   
      cpu    = var.cpu     
      memory = var.memory  
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}