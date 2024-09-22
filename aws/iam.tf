# Purpose: Create IAM roles and policies for SSM Patch Manager
resource "aws_iam_role" "ssm_patch_manager" {
  name = format("iam-role-ssm-patch-manager-%s-%s", var.service_name, var.env)
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "ssm.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ]
    }
  )

  tags = {
    Name     = format("iam-role-ssm-patch-manager-%s-%s", var.service_name, var.env)
    Resource = "IAM Role"
  }
}

resource "aws_iam_policy" "ssm_patch_manager_sns_access" {
  name = format("iam-policy-ssm-patch-manager-sns-access-%s-%s", var.service_name, var.env)
  path = "/"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sns:Publish"
          ]
          Resource = "${aws_sns_topic.ssm_patch_manager.arn}"
        }
      ]
    }
  )

  tags = {
    Name     = format("iam-policy-ssm-patch-manager-sns-access-%s-%s", var.service_name, var.env)
    Resource = "IAM Policy"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_patch_manager_sns_access" {
  role       = aws_iam_role.ssm_patch_manager.name
  policy_arn = aws_iam_policy.ssm_patch_manager_sns_access.arn
}

# Purpose: Create IAM role and policy for SSM Maintenance.
resource "aws_iam_role" "ssm_maintenance" {
  name = format("iam-role-ssm-maintenance-%s-%s", var.service_name, var.env)
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "ssm.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ]
    }
  )

  tags = {
    Name     = format("iam-role-ssm-maintenance-%s-%s", var.service_name, var.env)
    Resource = "IAM Role"
  }
}

resource "aws_iam_policy" "ssm_maintenance" {
  name = format("iam-policy-ssm-maintenance-%s-%s", var.service_name, var.env)
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : "*"
          "Condition" : {
            "StringEquals" : {
              "iam:PassedToService" : "ssm.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : "${aws_iam_role.ssm_patch_manager.arn}"
        }
      ]
    }
  )

  tags = {
    Name     = format("iam-policy-ssm-maintenance-%s-%s", var.service_name, var.env)
    Resource = "IAM Policy"
  }
}

data "aws_iam_policy" "ssm_maintenance" {
  for_each = toset([
    "AmazonSSMMaintenanceWindowRole",
    "AmazonSSMAutomationRole",
    aws_iam_policy.ssm_maintenance.name
  ])

  name = each.key
}

resource "aws_iam_role_policy_attachment" "ssm_maintenance" {
  for_each = data.aws_iam_policy.ssm_maintenance

  role       = aws_iam_role.ssm_maintenance.name
  policy_arn = each.value.arn
}

resource "aws_iam_policy" "ssm_automation_alb_patch" {
  name = format("iam-policy-ssm-automation-alb-patch-%s-%s", var.service_name, var.env)
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "iam:CreatePolicy",
            "iam:GetRole",
            "iam:PassRole",
            "iam:DeleteRolePolicy",
            "iam:DeletePolicy",
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:PutRolePolicy",
            "lambda:CreateFunction",
            "lambda:InvokeFunction",
            "lambda:DeleteFunction",
            "lambda:GetFunction",
            "lambda:ListTags",
          ]
          Resource = "*"
        }
      ]
    }
  )

  tags = {
    Name     = format("iam-policy-ssm-automation-alb-patch-%s-%s", var.service_name, var.env)
    Resource = "IAM Policy"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_automation_alb_patch" {
  role       = aws_iam_role.ssm_maintenance.name
  policy_arn = aws_iam_policy.ssm_automation_alb_patch.arn
}
