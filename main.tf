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
# [수정됨] 기존에 만들어진 LAW 이름 규칙 적용 (law-krc-dev-common)
data "azurerm_log_analytics_workspace" "law" {
  count               = var.create_environment ? 1 : 0
  name                = "law-krc-${var.env}-common" 
  resource_group_name = "rg-krc-${var.env}-common" # LAW가 위치한 공통 리소스 그룹 지정
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

  template {
    container {
      name   = var.app_name   # 컨테이너 내부 이름도 앱 이름과 동일하게 맞춤
      image  = var.image      # [수정됨] 주입받은 이미지 사용
      cpu    = var.cpu        # [수정됨] 주입받은 CPU 사용
      memory = var.memory     # [수정됨] 주입받은 메모리 사용
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port # [수정됨] 주입받은 포트 사용
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}