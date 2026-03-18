module "aca_app" {
  source = "../modules/aca-app"

  # 환경 설정
  env                = "stg"
  region             = "jpe"
  project            = "pointail"
  create_environment = true
  
  # 네트워크 (선택)
  infrastructure_subnet_id       = "/subscriptions/a98144a1-06aa-4136-9f70-d68d15be60f3/resourceGroups/rg-jpe-stg-common/providers/Microsoft.Network/virtualNetworks/vnet-jpe-stg-common/subnets/snet-jpe-stg-pointail-aca"
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true

  # 앱 설정
  app_name           = "temp-app-pointail"
  acr_server         = "" # MCR 사용 시 빈 문자열
  image              = "mcr.microsoft.com/k8se/quickstart:latest"
  cpu                = 0.25
  memory             = "0.5Gi"
  target_port        = 80

  # Secret & 민감 정보 (전달)
  uami_client_id     = var.uami_client_id
  subscription_id    = var.subscription_id
  uami_resource_id   = "/subscriptions/a98144a1-06aa-4136-9f70-d68d15be60f3/resourceGroups/rg-krc-stg-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-stg-acrpull"
}
