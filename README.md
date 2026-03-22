# Azure Container Apps (ACA) Terraform 배포 가이드

이 저장소는 GitHub Actions와 Terraform을 사용하여 다중 환경(dev, stg, prd)에 웹 앱(Web App)과 백그라운드 잡(Job)을 배포하는 인프라스트럭처 코드(IaC)입니다.

## 🏗 아키텍처 개요
- **공통 중앙 장부 (tfstate)**: `rg-krc-dev-common` 리소스 그룹 내 `sakrcdevktcloudshell` Storage Account에 상태 파일 통합 보관
- **러너 (Runner)**: 각 환경(dev, stg, prd)의 전용 Self-hosted VM 서버에서 격리되어 실행
- **인증 방식**: User-Assigned Managed Identity (UAMI) 기반 인증

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

> **💡 아키텍처 참고 (해외 리전 배포 전략)**
> `pointail` 프로젝트 등 일본(Japan East) 리전에 배포되는 Container App/Job의 경우, 굳이 일본 가상 네트워크(VNet) 내부에 배포 전용 러너(Runner) VM을 추가로 띄울 필요(망 종속성)가 없습니다. 따라서 효율적인 중앙 관리를 위해 **해당 파이프라인들은 모두 기존에 세팅해 둔 한국(KRC) 리전의 러너 장비(dev, stg, prd)를 그대로 사용하여 공통으로 원격 배포를 수행**합니다.

---

## 🔐 2. GitHub Actions 인증 및 시크릿(Secrets) 설정

GitHub 저장소의 **Settings -> Secrets and variables -> Actions**에 다음 환경변수들을 등록합니다. Client ID 값만 저장하면 됩니다.

| Secret Name | 설명 |
|---|---|
| `AZURE_TENANT_ID` | 소속된 Azure Tenant ID |
| `UAMI_CLIENT_ID_DEV` | DEV 환경용 Managed Identity(UAMI)의 Client ID |
| `UAMI_CLIENT_ID_STG` | STG 환경용 Managed Identity(UAMI)의 Client ID |
| `UAMI_CLIENT_ID_PRD` | PRD 환경용 Managed Identity(UAMI)의 Client ID |
| `SUB_ID_DEV` | DEV 구독 ID |
| `SUB_ID_STG` | STG 구독 ID |
| `SUB_ID_PRD` | PRD 구독 ID |

---

## 🛡️ 3. Azure RBAC(권한) 필수 설정 가이드

본 파이프라인은 보안 원칙(Separation of Duties)에 따라 **배포(파이프라인)용 관리 ID**와 **앱(런타임)용 관리 ID** 두 가지를 철저하게 분리하여 운영합니다. 각 환경(dev, stg, prd)의 관리 ID(UAMI)에 아래 권한들이 각각 정확하게 부여되어야 합니다.

### 👤 A. 배포용 관리 ID (GitHub Actions & 인프라 생성 역할)
파이프라인이 Azure에 로그인하여 인프라 뼈대(웹 앱, 잡, 로그 수집기 등)를 만들고 변경사항을 장부(tfstate)에 기록하는 주체입니다. (Secret의 `UAMI_CLIENT_ID_...` 에 해당하는 ID)

**1. 중앙 Terraform State 스토리지 접근 권한 (필수)**
- **대상**: DEV 구독의 `rg-krc-dev-common` 안의 `sakrcdevktcloudshell` 스토리지
- **권한**: `Storage Blob Data Contributor` (저장소 Blob 데이터 기여자)
- **할당 멤버**: DEV, STG, PRD **배포용 UAMI** 3개 모두 추가
  - `uami-krc-dev-github-runner`
  - `uami-krc-stg-github-runner`
  - `uami-krc-prd-github-runner`

**2. 전체 인프라 배포 권한 (필수)**
- **대상**: 배포할 대상 구독 (Subscription) 통째 지정
- **권한**: `Contributor` (기여자) 
- **할당 멤버**: 해당 배포 대상 환경의 **배포용 UAMI** 추가
  - DEV 구독: `uami-krc-dev-github-runner`
  - STG 구독: `uami-krc-stg-github-runner`
  - PRD 구독: `uami-krc-prd-github-runner`

---

### 👤 B. 앱 런타임용 관리 ID (AcrPull 역할 제한)
실제로 배포된 앱(`azurerm_container_app`) 또는 잡(`azurerm_container_app_job`) 자체에 신분증처럼 부착되어, 이미지 저장소에서 프라이빗 이미지를 다운받을 때만 사용되는 주체입니다. (테라폼 코드의 `uami_resource_id` 에 해당하는 ID)

**1. 프라이빗 레지스트리 다운로드 권한 (필수)**
- **대상**: 소속된 사내 프라이빗 Azure Container Registry (ACR) 리소스
- **권한**: `AcrPull`
- **할당 멤버**: 각 환경별 **앱 런타임용 UAMI** 추가
  - DEV 환경 앱 부착용: `uami-krc-dev-acrpull`
  - STG 환경 앱 부착용: `uami-krc-stg-acrpull`
  - PRD 환경 앱 부착용: `uami-krc-prd-acrpull`

---

## 📁 4. 디렉토리 설계 방식 (앱 vs 잡)

본 저장소는 배포 타겟 단위로 폴더가 분리되어 있습니다. 웹 앱과 백그라운드 잡(Job)은 서로 다른 서브넷을 갖지만, 동일한 Resource Group 내에 배포되도록 설계했습니다.

### 웹 앱(App) 배포 설정 (예: `env-pug`)
- `env-pug` / `env-pug-stg` / `env-pug-prd`
- **로직**: `create_environment = true` 만 설정
- **결과**: `rg-krc-dev-pug` 리소스 그룹 내에 `acaenv-krc-dev-pug` 환경 및 웹 앱이 배포됩니다.

### 배치 잡(Job) 배포 설정 (예: `env-pug-job`)
- `env-pug-job` / `env-pug-job-stg` / `env-pug-job-prd`
- **로직**: `is_job = true` 및 `cae_name = "acaenv-krc-dev-pug-job"` (서브넷 충돌을 막기 위해 환경 이름 강제 분리)
- **결과**: 앱과 똑같은 `rg-krc-dev-pug` 리소스 그룹 내에, 잡 전용 환경(`acaenv-krc-dev-pug-job`)과 잡이 배포됩니다.

### ♻️ 기존 환경(Environment)을 재사용하여 배포할 때 (신규 앱/잡 얹기)
이미 생성되어 운영 중인 Container App Environment에 새로운 앱이나 잡을 추가로 '얹어서' 배포해야 할 경우, 환경 생성 스위치를 끕니다.
- **로직**: `main.tf` 에서 `create_environment = false` 로 설정합니다.
- **필수 추가 변수**: 
  - `cae_name` = "기존에 만들어진 ACA 환경(Environment) 이름" 
  - (선택) `cae_rg_name` = "기존 ACA 환경이 소속된 리소스 그룹 이름" (기본 이름 규칙과 다를 경우만 명시)
- **결과**: 테라폼이 무겁고 오래 걸리는 새 환경 뼈대(VNet 연동, LAW 생성 등) 구축 단계를 완전히 건너뛰고, 기존 환경 내부로 빠르고 쾌적하게 컨테이너(App/Job)만 배포합니다.

---

## 🐳 5. 컨테이너 이미지(ACR / MCR) 및 Identity 설정

초기 인프라 세팅 단계에서는 프라이빗 저장소(ACR)와의 연동 에러를 방지하고 순수 인프라 검증을 하기 위해, Azure의 **퍼블릭 MCR(Microsoft Container Registry) 테스트 이미지**를 사용하도록 세팅되어 있습니다.

- **현재 상태 (퍼블릭 MCR 모드)**: `main.tf` 내부에 `acr_server = ""` 로 설정되어 있으며, 이미지는 `"mcr.microsoft.com/k8se/quickstart:latest"`를 바라봅니다. 이 경우 테라폼 모듈이 알아서 ACR 로그인(Registry) 연동 블럭을 제외하고 배포합니다.
- **실제 서비스 배포 (프라이빗 ACR 모드)**: 향후 실제 사내 앱을 배포하실 때는 `acr_server = "myacr.azurecr.io"`, `image = "myacr.azurecr.io/myapp:latest"` 와 같이 실제 값을 넣어주세요.
  - 이 값을 넣으면 테라폼이 자동으로 `var.uami_resource_id` (관리 ID 신분증)를 사용하여 ACR에 접근 권한을 행사하는 로직을 활성화시켜 줍니다! (이미 이 UAMI에는 ACR에서 이미지를 가져올 수 있는 `AcrPull` 연동 등 권한 세팅이 완벽하게 완료되어 있으므로, 아무런 권한 추가 작업 없이 단순히 저 주소 문자열만 추가하시면 곧바로 프라이빗 이미지를 당겨오게 됩니다!)

---

## 🛠️ 6. 파이프라인(배포/삭제) 실행 방법

GitHub의 **Actions** 탭에서 수동 트리거(workflow_dispatch)로 파이프라인을 실행합니다.

1. **Deploy ACA to Dev / Stg / Prd (최초 배포 및 업데이트)**
   - 배포할 환경(dev, stg, prd)에 맞는 파이프라인을 클릭합니다.
   - `Run workflow` 클릭 후, `app_dir` 입력 칸에 변경/배포할 폴더명(예: `env-pug` 또는 `env-pug-job-stg`)을 넣고 실행합니다.
   - 테라폼 코드가 기존 상태(tfstate)와 비교해 필요한 것만 생성(Create), 수정(Update), 삭제(Destroy) 등을 자동으로 계산하여 배포합니다.

2. **Destroy ACA in Dev (임시 환경 완전 삭제)**
   - 테스트 임시 환경이나 구조적 결함으로 환경을 통째로 지우고 재배포하고 싶을 때 사용합니다.
   - `app_dir` 입력 칸에 삭제할 폴더명(예: `env-data`)을 적고 실행하면 인프라와 상태 장부가 깨끗하게 삭제됩니다.
