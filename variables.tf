variable "env" {
  type        = string
  description = "배포 환경 (예: dev, stg, prd)"
}

variable "uami_client_id" {
  type        = string
  description = "VM에 부착된 관리 ID(UAMI)의 Client ID"
}

variable "acr_server" {
  type        = string
  description = "ACR 서버 주소 (예: myacr.azurecr.io)"
}

variable "subscription_id" {
  type        = string
  description = "배포 대상 구독 ID"
}

variable "create_environment" {
  type        = bool
  description = "true면 Container App 환경 새로 생성, false면 기존 환경 사용"
  default     = false
}

variable "cae_name" {
  type        = string
  description = "사용하거나 새로 생성할 Container App Environment의 정확한 이름"
}

variable "cae_rg_name" {
  type        = string
  description = "Container App Environment가 위치한 리소스 그룹 이름"
}

# [추가됨] Container App 이름을 위한 변수
variable "app_name" {
  type        = string
  description = "배포할 Container App의 정확한 이름"
}

variable "uami_resource_id" {
  type        = string
  description = "ACR에 접근하기 위한 UAMI(사용자 할당 관리 ID)의 Resource ID"
}

variable "uami_env_id" {
  type        = string
  description = "ACR에 접근하기 위한 SAMI(환경 시스템 할당 관리 ID)의 ID"
}

variable "image" {
  type        = string
  description = "배포할 컨테이너 이미지 (예: acrstorelinktestaca.azurecr.io/myapp:latest)"
}

variable "cpu" {
  type        = number
  description = "Container App에 할당할 CPU 코어 수 (예: 0.25, 0.5, 1.0 등)"
  default     = 0.25
}

variable "memory" {
  type        = string
  description = "Container App에 할당할 메모리 크기 (예: 0.5Gi, 1.0Gi, 2.0Gi 등)"
  default     = "0.5Gi"
}

variable "target_port" {
  type        = number
  description = "컨테이너 내 애플리케이션이 수신 대기하는 포트 번호"
  default     = 8080
}