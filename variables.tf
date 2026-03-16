variable "env" {
  type        = string
  description = "배포 환경 (예: dev, stg, prd)"
}

variable "uami_client_id" {
  type        = string
  description = "VM에 부착된 관리 ID(UAMI)의 Client ID"
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