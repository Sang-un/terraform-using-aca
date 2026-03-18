data "azurerm_resource_group" "app_rg" {
  name = "rg-krc-${var.env}-stl"
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

  # 서브넷 ID가 입력되었을 때만 커스텀 VNet 연동
  infrastructure_subnet_id       = var.infrastructure_subnet_id != "" ? var.infrastructure_subnet_id : null

  # (선택) 커스텀 서브넷을 쓸 때, 내부 통신만 허용할지 외부 인터넷도 허용할지 결정
  internal_load_balancer_enabled = var.internal_load_balancer_enabled

  # 가용성 영역 중복(Zone Redundancy) 활성화 설정
  zone_redundancy_enabled        = var.zone_redundancy_enabled
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
  # acr_server 변수가 입력되었을 때만 registry 설정을 추가합니다. (MCR 기본 이미지 등 퍼블릭 이미지 사용 지원)
  dynamic "registry" {
    for_each = var.acr_server != "" ? [1] : []
    content {
      server   = var.acr_server
      identity = var.uami_resource_id
    }
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