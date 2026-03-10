# =================
# SHARED WAREHOUSES
# =================
# Used by all environments (DEV, UAT, PROD)

resource "snowflake_warehouse" "dbt" {
  name           = "EFT_DATA_DBT_DEFAULT"
  comment        = "Warehouse for dbt transformations"
  warehouse_size = "XSMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}

resource "snowflake_warehouse" "fivetran" {
  name           = "EFT_DATA_FIVETRAN_DEFAULT"
  comment        = "Warehouse for Fivetran data loading"
  warehouse_size = "XSMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}

resource "snowflake_warehouse" "powerbi" {
  name           = "EFT_DATA_POWERBI_DEFAULT"
  comment        = "Warehouse for Power BI queries"
  warehouse_size = "SMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}

resource "snowflake_warehouse" "analytics" {
  name           = "EFT_DATA_ANALYTICS"
  comment        = "Warehouse for analytical queries"
  warehouse_size = "SMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}


resource "snowflake_warehouse" "dbt-prod" {
  name           = "EFT_DATA_DBT_PROD"
  comment        = "Warehouse for dbt transformations"
  warehouse_size = "XSMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}



resource "snowflake_warehouse" "dbt-dev" {
  name           = "EFT_DATA_DBT_DEV"
  comment        = "Warehouse for dbt transformations"
  warehouse_size = "XSMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}



resource "snowflake_warehouse" "dbt-uat" {
  name           = "EFT_DATA_DBT_UAT"
  comment        = "Warehouse for dbt transformations"
  warehouse_size = "XSMALL"
  
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  max_cluster_count                   = 1
  min_cluster_count                   = 1
  scaling_policy                      = "STANDARD"
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  
  lifecycle {
    ignore_changes = [
      warehouse_size,
      max_cluster_count,
      min_cluster_count,
      scaling_policy,
      auto_suspend,
      auto_resume,
      initially_suspended,
      enable_query_acceleration,
      query_acceleration_max_scale_factor
    ]
  }
}