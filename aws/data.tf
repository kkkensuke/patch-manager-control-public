data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_instance" "instances" {
  for_each = var.maintenance_schedules

  filter {
    name   = "tag:Name"
    values = [each.key]
  }
}
