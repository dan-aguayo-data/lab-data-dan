# =================
# GLOBAL RESOURCES
# =================
# Resources shared across all environments (DEV, UAT, PROD)
#
# This folder contains:
# - Service accounts (SVC_DATA_DBT, SVC_DATA_FIVETRAN, SVC_DATA_POWERBI)
# - Service roles (SVC_ROLE_DBT_RW, SVC_ROLE_FIVETRAN_RW, SVC_ROLE_POWERBI_RO)
# - Warehouses (EFT_DATA_DBT_DEFAULT, EFT_DATA_FIVETRAN_DEFAULT, etc.)
#
# Resources are defined in separate files:
# - service_accounts.tf
# - warehouses.tf
#
# Outputs are exported for environments to reference via remote state
