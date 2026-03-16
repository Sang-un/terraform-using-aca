# 환경 관련 변수
env                = "dev"
create_environment = false
cae_name           = "cae-krc-dev-common" # 실제 사용할 환경 이름으로 변경
cae_rg_name        = "rg-krc-dev-stl"     # 환경이 속한 리소스 그룹

# 컨테이너 앱 설정 변수
app_name           = "test-app-dev"       # 실제 배포할 앱 이름으로 변경
image              = "acrstorelinktestaca.azurecr.io/myapp:latest" # 실제 이미지 주소
cpu                = 0.25
memory             = "0.5Gi"
target_port        = 8080
