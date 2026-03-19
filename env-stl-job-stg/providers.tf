terraform {
  backend "azurerm" {} # GitHub Actions에서 초기화 시 주입됨
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
  use_msi                    = true
  client_id                  = var.uami_client_id
  subscription_id            = var.subscription_id
  skip_provider_registration = true # 권한 에러 방지용 (필수)
}