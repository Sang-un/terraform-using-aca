# 환경 관련 변수
env                = "dev"
create_environment = false
cae_name           = "acaenv-n-n" # 실제 사용할 환경 이름으로 변경
cae_rg_name        = "rg-krc-dev-stl"     # 환경이 속한 리소스 그룹

# 컨테이너 앱 설정 변수
app_name           = "test-app-dev"       # 실제 배포할 앱 이름으로 변경
acr_server         = "acrstorelinktestaca.azurecr.io"
image              = "acrstorelinktestaca.azurecr.io/web-info:v1" # 실제 이미지 주소
cpu                = 0.25
memory             = "0.5Gi"
target_port        = 80
uami_resource_id   = "/subscriptions/a98144a1-06aa-4136-9f70-d68d15be60f3/resourceGroups/rg-krc-dev-common/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-krc-dev-github-runner"
uami_env_id        = "33d5857b-4225-408a-bf8d-bc64373392b0"
