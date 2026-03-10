# =================
# ENVIRONMENT MODULE
# =================
# Reusable module for creating environment-specific resources
#
# This module creates:
# - Databases with environment suffix (e.g., STAGING_DEV, DWH_MART_PROD)
# - Schemas within databases
# - Environment-specific analyst roles (e.g., SF_DATA_ANALYST_DEV_RO)
# - Grants connecting global service accounts to environment databases
# - Grants connecting analyst roles to environment databases
#
# Resources are defined in separate files:
# - databases.tf: Database and schema creation logic
# - analyst_roles.tf: Environment-specific analyst roles
# - grants_service_accounts.tf: Connect global service accounts (DBT, Fivetran, PowerBI)
# - grants_analyst_roles.tf: Connect analyst roles to databases
#
# This module is called by each environment (dev, uat, prod) with different parameters
