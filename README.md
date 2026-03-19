# Azure Container Apps (ACA) Terraform 배포 가이드

이 저장소는 GitHub Actions와 Terraform을 사용하여 다중 환경(dev, stg, prd)에 웹 앱(Web App)과 백그라운드 잡(Job)을 배포하는 인프라스트럭처 코드(IaC)입니다.

## 🏗 아키텍처 개요
- **공통 중앙 장부 (tfstate)**: `rg-krc-dev-common` 리소스 그룹 내 `sakrcdevktcloudshell` Storage Account에 상태 파일 통합 보관
- **러너 (Runner)**: 각 환경(dev, stg, prd)의 전용 Self-hosted VM 서버에서 격리되어 실행
- **인증 방식**: Azure AD (OIDC) 및 User-Assigned Managed Identity (UAMI) 기반 인증으로 Access Key 미사용

---

## 🚀 1. VM 설정 및 Runner / Terraform 설치
각 환경(dev, stg, prd)의 VM 서버에 접속하여 다음 패키지들을 설치하고 러너를 등록합니다.

```sh
# 1. 패키지 업데이트 및 필요 도구 설치
sudo apt-get update && sudo apt-get install -y unzip curl git

# 2. Terraform 설치
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# 3. Azure CLI 설치
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 4. GitHub Runner 설치 (각 환경별 VM에서 실행)
# GitHub Repo -> Settings -> Actions -> Runners -> New self-hosted runner
./config.sh --url https://github.com/Sang-un/terraform-using-aca --token <YOUR_TOKEN> --labels dev
# (STG VM에서는 --labels stg, PRD VM에서는 --labels prd 로 지정)
```

---

## 🔐 2. GitHub Actions 인증 및 시크릿(Secrets) 설정

GitHub 저장소의 **Settings -> Secrets and variables -> Actions**에 다음 환경변수들을 등록합니다. OIDC 형식을 지원하므로 Client ID 값만 저장하면 됩니다.

| Secret Name | 설명 |
|---|---|
| `AZURE_TENANT_ID` | 소속된 Azure Tenant ID |
| `UAMI_CLIENT_ID_DEV` | DEV 환경용 Managed Identity(UAMI)의 Client ID |
| `UAMI_CLIENT_ID_STG` | STG 환경용 Managed Identity(UAMI)의 Client ID |
| `UAMI_CLIENT_ID_PRD` | PRD 환경용 Managed Identity(UAMI)의 Client ID |
| `SUB_ID_DEV` | DEV 구독 ID |
| `SUB_ID_STG` | STG 구독 ID |
| `SUB_ID_PRD` | PRD 구독 ID |

*(참고: 각 구독의 관리 ID(UAMI) 쪽 Azure 포털 설정(Federated Credentials)에서 이 GitHub Repository의 main 브랜치 접근을 허락해 주어야 합니다.)*

---

## 🛡️ 3. Azure RBAC(권한) 필수 설정 가이드

테라폼 백엔드 중앙 집중화 및 컨테이너 앱 배포를 위해, 환경별 관리 ID(UAMI)에 다음 권한들이 반드시 부여되어야 합니다.

**1. 중앙 Terraform State 스토리지 접근 권한 (필수)**
- **대상**: DEV 구독의 `rg-krc-dev-common` 안의 `sakrcdevktcloudshell` Storage Account
- **권한**: `Storage Blob Data Contributor` (저장소 Blob 데이터 기여자)
- **할당 멤버**: DEV, STG, PRD 관리 ID 3개 모두 추가 (tfstate 읽고 쓰기용)

**2. 커스텀 VNet 서브넷 배포 권한 (필수)**
- **대상**: 각 환경별 VNet 네트워크 리소스 그룹 (예: `rg-krc-dev-common`, `rg-krc-stg-common`, `rg-krc-prd-common`)
- **권한**: `Network Contributor` (네트워크 기여자)
- **할당 멤버**: 해당 환경용 관리 ID (예: STG VNet에는 STG 관리 ID 지정)

**3. 해당 환경 배포 권한 (필수)**
- **대상**: 배포할 대상 구독 (Subscription) 통째 지정
- **권한**: `Contributor` (기여자) 
- **할당 멤버**: 해당 환경용 관리 ID

---

## 📁 4. 디렉토리 설계 방식 (앱 vs 잡)

본 저장소는 배포 타겟 단위로 폴더가 분리되어 있습니다. 웹 앱과 백그라운드 잡(Job)은 서로 다른 서브넷을 갖지만, 동일한 Resource Group 내에 배포되도록 설계되었습니다.

### 웹 앱(App) 배포 설정 (예: `env-pug`)
- `env-pug` / `env-pug-stg` / `env-pug-prd`
- **로직**: `create_environment = true` 만 설정
- **결과**: `rg-krc-dev-pug` 리소스 그룹 내에 `acaenv-krc-dev-pug` 환경 및 웹 앱이 배포됩니다.

### 배치 잡(Job) 배포 설정 (예: `env-pug-job`)
- `env-pug-job` / `env-pug-job-stg` / `env-pug-job-prd`
- **로직**: `is_job = true` 및 `cae_name = "acaenv-krc-dev-pug-job"` (서브넷 충돌을 막기 위해 환경 이름 강제 분리)
- **결과**: 앱과 똑같은 `rg-krc-dev-pug` 리소스 그룹 내에, 잡 전용 환경(`acaenv-krc-dev-pug-job`)과 잡이 배포됩니다.

---

## 🛠️ 5. 파이프라인(배포/삭제) 실행 방법

GitHub의 **Actions** 탭에서 수동 트리거(workflow_dispatch)로 파이프라인을 실행합니다.

1. **Deploy ACA to Dev / Stg / Prd (최초 배포 및 업데이트)**
   - 배포할 환경(dev, stg, prd)에 맞는 파이프라인을 클릭합니다.
   - `Run workflow` 클릭 후, `app_dir` 입력 칸에 변경/배포할 폴더명(예: `env-pug` 또는 `env-pug-job-stg`)을 넣고 실행합니다.
   - 테라폼 코드가 기존 상태(tfstate)와 비교해 필요한 것만 생성(Create), 수정(Update), 삭제(Destroy) 등을 자동으로 계산하여 배포합니다.

2. **Destroy ACA in Dev (임시 환경 완전 삭제)**
   - 테스트 임시 환경이나 구조적 결함으로 환경을 통째로 지우고 재배포하고 싶을 때 사용합니다.
   - `app_dir` 입력 칸에 삭제할 폴더명(예: `env-data`)을 적고 실행하면 인프라와 상태 장부가 깨끗하게 삭제됩니다.
