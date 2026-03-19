module "aca_app" {
  source = "../modules/aca-app"

  # 환경 설정
  env                = "prd"
  region             = "krc"
  project            = "stl"
  create_environment = false
  # cae_name           = "cae-krc-prd-common"
  # cae_rg_name        = "rg-krc-prd-stl" 
  
  # 앱 설정
  app_name           = "test-app-prd"
  acr_server         = "acrstorelinktestaca.azurecr.io"
  image              = "acrstorelinktestaca.azurecr.io/myapp:latest"
  cpu                = 0.25
  memory             = "0.5Gi"
  target_port        = 8080

  # Secret & 민감 정보 (전달)
  uami_client_id     = var.uami_client_id
  subscription_id    = var.subscription_id
  uami_resource_id   = "/subscriptions/d08e1c28-7a9a-4a3d-99ce-d74857edff01/resourceGroups/rg-krc-prd-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-prd-acrpull"
}