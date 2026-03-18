module "aca_app" {
  source = "../modules/aca-app"

  # 환경 설정
  env                = "prd"
  region             = "krc"
  project            = "data"
  create_environment = true
  # cae_name           = "acaenv-krc-prd-data"
  # cae_rg_name        = "rg-krc-prd-data"
  
  # 네트워크 (선택)
  infrastructure_subnet_id       = "/subscriptions/a98144a1-06aa-4136-9f70-d68d15be60f3/resourceGroups/rg-krc-prd-common/providers/Microsoft.Network/virtualNetworks/vnet-krc-prd-common/subnets/snet-krc-prd-data-aca"
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true

  # 앱 설정
  app_name           = "temp-app-data"
  acr_server         = "" # MCR 사용 시 빈 문자열
  image              = "mcr.microsoft.com/k8se/quickstart:latest"
  cpu                = 0.25
  memory             = "0.5Gi"
  target_port        = 80

  # Secret & 민감 정보 (전달)
  uami_client_id     = var.uami_client_id
  subscription_id    = var.subscription_id
  uami_resource_id   = "/subscriptions/a98144a1-06aa-4136-9f70-d68d15be60f3/resourceGroups/rg-krc-prd-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-prd-acrpull"
}
