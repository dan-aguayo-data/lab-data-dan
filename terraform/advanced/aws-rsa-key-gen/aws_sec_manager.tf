# =============================================================================
# Secrets Manager - RSA Key Storage
# =============================================================================

# -----------------------------------------------------------------------------
# RSA1 Secrets (Primary Key Slot)
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "rsa1_private" {
  for_each = var.service_accounts

  name        = "data/dwh/snowflake/${each.key}_rsa1_private"
  description = "RSA1 private key for Snowflake ${each.value.snowflake_user}"

  tags = merge(local.common_tags, {
    ServiceAccount = each.key
    KeySlot        = "rsa1"
    KeyType        = "private"
  })
}

resource "aws_secretsmanager_secret" "rsa1_public" {
  for_each = var.service_accounts

  name        = "data/dwh/snowflake/${each.key}_rsa1"
  description = "RSA1 public key for Snowflake ${each.value.snowflake_user}"

  tags = merge(local.common_tags, {
    ServiceAccount = each.key
    KeySlot        = "rsa1"
    KeyType        = "public"
  })
}

# -----------------------------------------------------------------------------
# RSA2 Secrets (Secondary Key Slot - for rotation)
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "rsa2_private" {
  for_each = var.service_accounts

  name        = "data/dwh/snowflake/${each.key}_rsa2_private"
  description = "RSA2 private key for Snowflake ${each.value.snowflake_user}"

  tags = merge(local.common_tags, {
    ServiceAccount = each.key
    KeySlot        = "rsa2"
    KeyType        = "private"
  })
}

resource "aws_secretsmanager_secret" "rsa2_public" {
  for_each = var.service_accounts

  name        = "data/dwh/snowflake/${each.key}_rsa2"
  description = "RSA2 public key for Snowflake ${each.value.snowflake_user}"

  tags = merge(local.common_tags, {
    ServiceAccount = each.key
    KeySlot        = "rsa2"
    KeyType        = "public"
  })
}



# =============================================================================
# Manual inputs -- > GitHub Token Secret
# =============================================================================

resource "aws_secretsmanager_secret" "github_token" {
  name        = "data/github/dataplatform-au-dbt/classic_token"
  description = "GitHub classic token for data-dbt repo"

  tags = merge(local.common_tags, {
    Purpose = "github-access"
  })
}
