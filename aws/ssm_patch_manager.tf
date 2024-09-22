# Baseline
resource "aws_ssm_patch_baseline" "aml2" {
  name             = format("CustomBaseline-%s-%s", var.service_name, var.env)
  description      = "Custom Baseline for AmazonLinux2"
  operating_system = "AMAZON_LINUX_2"
  #rejected_patches = ["ALAS-2021-1234"] # specify the patches that you want to exclude from the baseline

  approval_rule {
    approve_after_days  = var.ssm_patch_baseline["linux"]["approve_after_days"]
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  approval_rule {
    approve_after_days  = var.ssm_patch_baseline["linux"]["approve_after_days"]
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Bugfix"]
    }
  }
}

# Patch Group (it needs to specify each instance ID as Automation argument)
resource "aws_ssm_patch_group" "patch_group" {
  for_each = var.maintenance_schedules

  baseline_id = aws_ssm_patch_baseline.aml2.id
  patch_group = format("PatchGroup-%s-%s", var.service_name, each.key) # Targeted instances should have the tag "PatchGroup" with this value.
}

# Maintenance Window
resource "aws_ssm_maintenance_window" "patch_scan" {
  for_each = var.maintenance_schedules

  enabled                    = true
  name                       = format("PatchScan-%s-%s", var.service_name, each.key)
  schedule                   = each.value.scan
  duration                   = 3
  cutoff                     = 1
  allow_unassociated_targets = true

  tags = {
    Resource = "Maintenance Window"
  }
}

resource "aws_ssm_maintenance_window" "patch_install" {
  for_each = var.maintenance_schedules

  enabled                    = true
  name                       = format("PatchInstall-%s-%s", var.service_name, each.key)
  schedule                   = each.value.install
  duration                   = 3
  cutoff                     = 1
  allow_unassociated_targets = true

  tags = {
    Resource = "Maintenance Window"
  }
}

# Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "patch_scan" {
  for_each = var.maintenance_schedules

  window_id     = aws_ssm_maintenance_window.patch_scan[each.key].id
  name          = format("PatchScanTarget-%s-%s", var.service_name, each.key)
  resource_type = "INSTANCE"

  # Targeted instances should have the tag "PatchGroup" with the value of the patch group
  targets {
    key    = "tag:PatchGroup"
    values = [aws_ssm_patch_group.patch_group[each.key].patch_group]
  }
}

resource "aws_ssm_maintenance_window_target" "patch_install" {
  for_each = var.maintenance_schedules

  window_id     = aws_ssm_maintenance_window.patch_install[each.key].id
  name          = format("PatchInstallTarget-%s-%s", var.service_name, each.key)
  resource_type = "INSTANCE"

  # Targeted instances should have the tag "PatchGroup" with the value of the patch group
  targets {
    key    = "tag:PatchGroup"
    values = [aws_ssm_patch_group.patch_group[each.key].patch_group]
  }
}

# Maintenance Window Task
resource "aws_ssm_maintenance_window_task" "patch_scan" {
  for_each = var.maintenance_schedules

  window_id        = aws_ssm_maintenance_window.patch_scan[each.key].id
  name             = format("PatchScanTask-%s-%s", var.service_name, each.key)
  task_arn         = "AWS-RunPatchBaseline"
  task_type        = "RUN_COMMAND"
  max_concurrency  = 1
  max_errors       = 1
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_scan[each.key].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      service_role_arn = aws_iam_role.ssm_patch_manager.arn

      notification_config {
        notification_arn    = aws_sns_topic.ssm_patch_manager.arn
        notification_events = ["Failed"]
        notification_type   = "Command"
      }

      parameter {
        name   = "Operation"
        values = ["Scan"]
      }

      parameter {
        name   = "RebootOption"
        values = ["NoReboot"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "patch_install" {
  for_each = var.maintenance_schedules

  window_id        = aws_ssm_maintenance_window.patch_install[each.key].id
  name             = format("PatchInstallTask-%s-%s", var.service_name, each.key)
  task_arn         = data.aws_ssm_document.patch_lb_instance.arn
  task_type        = "AUTOMATION"
  max_concurrency  = 1
  max_errors       = 1
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_install[each.key].id]
  }

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "InstanceID"
        values = [data.aws_instance.instances[each.key].id]
      }

      parameter {
        name   = "ConnectionDrainTime"
        values = ["5"]
      }
    }
  }
}
