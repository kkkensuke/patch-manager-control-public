# SNS Topic for Patch Manager
resource "aws_sns_topic" "ssm_patch_manager" {
  name = format("ssm-patch-manager-%s-%s", var.service_name, var.env)

  tags = {
    Name     = format("ssm-patch-manager-%s-%s", var.service_name, var.env)
    Resource = "SNS Topic"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ssm_patch_manager.arn
  protocol  = "email"
  endpoint  = var.sns_topic_subscription_endpoint["email"]
}

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.ssm_patch_manager.arn
  protocol  = "email"
  endpoint  = var.sns_topic_subscription_endpoint["email_to_slack"]
}

resource "aws_sns_topic_policy" "ssm_patch_manager" {
  arn = aws_sns_topic.ssm_patch_manager.arn
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "${aws_iam_role.ssm_patch_manager.arn}"
          },
          "Action" : "sns:Publish",
          "Resource" : aws_sns_topic.ssm_patch_manager.arn,
        }
      ]
    }
  )
}