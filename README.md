# patch-manager-control-public
This repository contains AWS resources and configuration for managing patching for EC2 instance.
<img width="712" alt="image" src="https://github.com/user-attachments/assets/27350c2b-1868-448d-ba03-a9edf5f1afd1">

## HOW IT WORKS
This repository resorce setup below AWS resources.
- IAM Roles and Policies for PatchManager/MaintenanceWindow
- SNS TOPIC and subscription for your notification target
- SSM PatchBaseline for AmazonLinux2
- SSM PatchGroup
- SSM Maintenance Window including:
  - Maintenance Window Target
  - Maintenance Window Task
    - scan by RunCommand
    - install by Automation (Using AWSEC2-PatchLoadBalancerInstance Document)

Maintenance Window Schedule is configured on `variables.tf`. 
```
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
    # When you have more EC2 for patching, you can simply adding your new schedule configuration here.
  }
}
```

- Maintenance Window targeting it's EC2 by filtering EC2's tag key `tag:PatchGroup` and it's value. The value of `tag:PatchGroup` should match `maintenance_schedules` of above variables.tf file.

- As an AUTOMATION Document, it uses [AWSEC2-PatchLoadBalancerInstance](https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-awsec2-patch-load-balancer-instance.html) which Upgrade and patch minor version of an Amazon EC2 instance (Windows or Linux) attached to any load balancer (classic, ALB, or NLB). 
