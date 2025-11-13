resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = "${var.parameter_prefix}${each.key}"
  type        = lookup(each.value, "type", "String")
  value       = each.value.value
  description = lookup(each.value, "description", null)
  tier        = lookup(each.value, "tier", "Standard")
  overwrite   = lookup(each.value, "overwrite", true)
  tags        = var.tags
}
