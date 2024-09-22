variable "env" {
  type    = string
  default = "dev"
}

variable "service_name" {
  type    = string
  default = "patch-control"
}

variable "sns_topic_subscription_endpoint" {
  default = {
    "slack"          = "https://global.sns-api.chatbot.amazonaws.com"
    "email"          = "your-email-address"
    "email_to_slack" = "When you setup your slack channel to receive email, you will get an endpoint. Use that endpoint here."
  }
}

variable "ssm_patch_baseline" {
  default = {
    "linux" = {
      "approve_after_days" = 7
    }
  }
}

variable "maintenance_schedules" {
  description = "Map of instance name and Maintenance Window Schedule for scan and install"
  default = {
    "your_instance_1" = {
      scan    = "cron(5 23 ? * TUE#2 *)"
      install = "cron(30 23 ? 1,4,7,10 WED#2 *)"
    }
    "your_instance_2" = {
      scan    = "cron(set up cron for your secound instance scan)"
      install = "cron(set up cron for your secound instance install)"
    }
  }
}
