############################################
# CLOUDWATCH LOG GROUP
############################################

resource "aws_cloudwatch_log_group" "dbt" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Name = var.log_group_name
  }
}

############################################
# STEP FUNCTIONS LOG GROUP
############################################

resource "aws_cloudwatch_log_group" "step_functions" {
  count = var.enable_step_functions ? 1 : 0

  name              = "/aws/stepfunctions/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/stepfunctions/${local.name_prefix}"
  }
}
