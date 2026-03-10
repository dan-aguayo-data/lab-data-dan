output "analyst_ro_role" {
  description = "Name of the read-only analyst role"
  value       = local.analyst_ro_role_name
}

output "analyst_sec_ro_role" {
  description = "Name of the security read-only analyst role"
  value       = local.analyst_sec_ro_role_name
}

output "analyst_rw_role" {
  description = "Name of the read-write analyst role (DEV only)"
  value       = var.environment == "dev" ? local.analyst_rw_role_name : null
}
