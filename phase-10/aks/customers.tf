
locals {
  customers = toset([
    "erik",
    "maria",
  ])

  environment = "n8n"
  domain = "n8n.huntrrose.com"
  gitops_repo_path = "/workspaces/iacazure/phase-10/n8n/"

  customers_sorted = sort(tolist(local.customers))
}

module "customer" {
  source = "../modules/customer-onboarding"
  for_each = local.customers

  customer_name = each.key
  environment = local.environment

  key_vault_id = azurerm_key_vault.n8n_vault.id
  storage_account_id = azurerm_storage_account.cnpg_backups.id
  storage_account_name = azurerm_storage_account.cnpg_backups.name
  storage_account_primary_connection_string = azurerm_storage_account.cnpg_backups.storage_account_primary_connection_string

  keyvault_name = azurerm_key_vault.n8n_vault.name
  key_vault_tenant_id = data.azurerm_client_config.current.tenant_id 
  aks_keyvault_identity_client_id = azurerm_kubernetes_cluster.main.azurerm_key_vault_secret_provider[0].secret_identity[0].client_id
  
  gitops_repo_path = local.gitops_repo_path
  domain = local.domain

  depends_on = [azurerm_role_assignment.kv_admin]
}
## Customer1 DB credentials

resource "local_file" "staging_kustomization" {
  filename  = "${local.gitops_repo_path}/apps/staging/kustomization.yaml"
  content = <<-YAML
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    %{for customer in local.customers_sorted~}
      - ${customer}
    %{endfor~}
  YAML

  depends_on = [module.customer]
}

## Add generating kustomization for system to avoid manual update of client_id
