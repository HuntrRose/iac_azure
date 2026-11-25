resource "random_password" "db_password" {
  length  = 24
  special = false

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_key_vault_secret" "db_user" {
  name         = "${var.customer_name}-db-user"
  value        = "app"
  key_vault_id = var.keyvault_id
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "${var.customer_name}-db-password"
  value        = random_password.db_password.result
  key_vault_id = var.keyvault_id
}

resource "azurerm_key_vault_secret" "blob_sas" {
  name         = "${var.customer_name}-blob-sas"
  value        = data.azurerm_storage_account_blob_container_sas.customer.sas
  key_vault_id = var.keyvault_id
}

# Telegram credentials (dummy values for demo)
# Comment these out and create real secrets manually if using Telegram
resource "azurerm_key_vault_secret" "telegram_bot_token" {
  name         = "${var.customer_name}-telegram-bot-token"
  value        = "DEMO:dummy-bot-token-replace-me"
  key_vault_id = var.keyvault_id

  lifecycle {
    ignore_changes = [value] # Allow manual updates without Terraform overwriting
  }
}

resource "azurerm_key_vault_secret" "telegram_chat_id" {
  name         = "${var.customer_name}-telegram-chat-id"
  value        = "000000000"
  key_vault_id = var.keyvault_id

  lifecycle {
    ignore_changes = [value] # Allow manual updates without Terraform overwriting
  }
}
