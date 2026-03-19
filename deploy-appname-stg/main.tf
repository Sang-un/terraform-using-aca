module "aca_app" {
  source = "../modules/aca-app"

  # 환경 설정
  env                = "stg"
  region             = "krc"
  project            = "stl"
  create_environment = false
  # cae_name           = "cae-krc-stg-common"
  # cae_rg_name        = "rg-krc-stg-stl" 
  
  # 앱 설정
  app_name           = "test-app-stg"
  acr_server         = "acrstorelinktestaca.azurecr.io"
  image              = "acrstorelinktestaca.azurecr.io/myapp:latest"
  cpu                = 0.25
  memory             = "0.5Gi"
  target_port        = 8080

  # Secret & 민감 정보 (전달)
  uami_client_id     = var.uami_client_id
  subscription_id    = var.subscription_id
  uami_resource_id   = "/subscriptions/bc08b927-9eba-423d-a61f-bc444d048ec9/resourceGroups/rg-krc-stg-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-stg-acrpull"
}