module "aca_app" {
  source = "../modules/aca-app"

  # 환경 설정
  env                = "stg"
  region             = "krc"
  project            = "pug-job"
  create_environment = true
  
  # 네트워크 (선택)
  infrastructure_subnet_id       = "/subscriptions/bc08b927-9eba-423d-a61f-bc444d048ec9/resourceGroups/rg-krc-stg-common/providers/Microsoft.Network/virtualNetworks/vnet-krc-stg-common/subnets/snet-krc-stg-pug-job-aca"
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true

  # 앱 설정
  app_name           = "temp-app-pug-job"
  acr_server         = "" # MCR 사용 시 빈 문자열
  image              = "mcr.microsoft.com/k8se/quickstart:latest"
  cpu                = 0.25
  memory             = "0.5Gi"
  target_port        = 80

  # Secret & 민감 정보 (전달)
  uami_client_id     = var.uami_client_id
  subscription_id    = var.subscription_id
  uami_resource_id   = "/subscriptions/bc08b927-9eba-423d-a61f-bc444d048ec9/resourceGroups/rg-krc-stg-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-stg-acrpull"
}
