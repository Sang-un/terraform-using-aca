module "aca_app" {
  source = "../modules/aca-app"

  # 환경 설정
  env                = "dev"
  create_environment = false
  cae_name           = "cae-krc-dev-common"
  cae_rg_name        = "rg-krc-dev-stl"
  
  # 앱 설정
  app_name           = "test-app-dev"
  acr_server         = "acrstorelinktestaca.azurecr.io"
  image              = "acrstorelinktestaca.azurecr.io/myapp:latest"
  cpu                = 0.25
  memory             = "0.5Gi"
  target_port        = 8080

  # Secret & 민감 정보 (전달)
  uami_client_id     = var.uami_client_id
  subscription_id    = var.subscription_id
  uami_resource_id   = "/subscriptions/a98144a1-06aa-4136-9f70-d68d15be60f3/resourceGroups/rg-krc-dev-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-dev-acrpull"
}