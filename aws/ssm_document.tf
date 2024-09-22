# SSM Custom AWSEC2-PatchLoadBalancerInstance
data "aws_ssm_document" "patch_lb_instance" {
  name            = "AWSEC2-PatchLoadBalancerInstance"
  document_format = "JSON"
}
