terraform {
  required_version = ">= 0.12.1" # resolver 
}

#########################################################################################
# Provider Section:  NOTE - update role_arn to the role with access in the target account
#########################################################################################
provider "aws" {
  region = "${var.region}"
#  assume_role {
# Update with appropriate role below:    
#   role_arn = "arn:aws:iam::<account number>:role/OrganizationAccountAccessRole"
#  }
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
# ######################################
# # DNS Resolver Security Group
# ######################################
resource "aws_security_group" "resolver-sg" {
  name        = "${format("network-%s-resolver-%s-sg", var.environment, var.region)}"
  description = "Allow DNS inbound traffic"
  vpc_id      = "${var.vpc-id}"

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["10.10.1.250/32","10.10.2.250/32"]
  }

  tags     = "${merge(var.tags, map("Name", format("%s-%s-resolver-security-group", var.team_name, var.environment)))}"
}
######################################
# DNS resolver endpoint
######################################
resource "aws_route53_resolver_endpoint" "endpoint" {
  depends_on = ["aws_security_group.resolver-sg"]
  name      = "${format("%s-resolver-%s-outbound-eni", var.environment, var.region)}"
  direction = "OUTBOUND"

  security_group_ids = [
    "${aws_security_group.rte53-resolver-sg.id}"
  ]
  #Subnet IDs are below. At least 2 subnets must exist for resolver endpoint.
  ip_address {
    subnet_id = "${var.subnet-ids[0]}"
    #optional IP address of the endpoint
    ip        = "${var.endpoint-ips[0]}"
  }
  ip_address {
    subnet_id = "${var.subnet-ids[1]}"
    #optional IP address of the endpoint
    ip        = "${var.endpoint-ips[1]}"
  }

  tags     = "${merge(var.tags, map("Name", format("%s-%s-resolver-outbound-endpoint", var.team_name, var.environment)))}"
}
######################################
# DNS resolver rules
######################################
# Recursive Internet resolver rule is not usually needed - it is created automatically
# resource "aws_route53_resolver_rule" "Internet-Resolver" {
#   domain_name          = "."
#   name                 = "Internet Resolver"
#   rule_type            = "RECURSIVE"
# }
resource "aws_route53_resolver_rule" "reverse-10" {
  domain_name          = "10.in-addr.arpa."
  name                 = "10-in-addr-arpa"
  rule_type            = "FORWARD"
  resolver_endpoint_id = "${aws_route53_resolver_endpoint.endpoint.id}"
  target_ip {
    ip = "${var.forwarders[0]}"
  }
  target_ip {
    ip = "${var.forwarders[1]}"
  }

  tags     = "${merge(var.tags, map("Name", format("%s-%s-reverse-lookup-10", var.team_name, var.environment)))}"
}
resource "aws_route53_resolver_rule" "forward-lavrichev-com" {
  domain_name          = "lavrichev.com."
  name                 = "lavrichev-com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = "${aws_route53_resolver_endpoint.endpoint.id}"
  target_ip {
    ip = "${var.forwarders[0]}"
  }
  target_ip {
    ip = "${var.forwarders[1]}"
  }

  tags     = "${merge(var.tags, map("Name", format("%s-%s-forward-lookup-factset-com", var.team_name, var.environment)))}"
}

######################################
# Resource sharing
######################################
resource "aws_ram_resource_share" "resolver-share" {
  name						          = "${format("internal-lavrichev-dns-resolver-%s-share", var.region)}"
  allow_external_principals = false

  tags = "${merge(var.tags, map("Name", format("internal-lavrichev-dns-resolver-%s-share", var.region)))}"
}
resource "aws_ram_principal_association" "main organization-association" {
  principal          = "arn:aws:organizations::<organization-arn>"
  resource_share_arn = "${aws_ram_resource_share.resolver-share.arn}"
}
resource "aws_ram_resource_association" "reverse-10-association" {
  resource_arn       = "${aws_route53_resolver_rule.reverse-10.arn}"
  resource_share_arn = "${aws_ram_resource_share.resolver-share.arn}"
}
resource "aws_ram_resource_association" "forward-lavrichev-com-association" {
  resource_arn       = "${aws_route53_resolver_rule.forward-lavrichev-com.arn}"
  resource_share_arn = "${aws_ram_resource_share.resolver-share.arn}"
}

######################################
# DNS resolver rule associations
######################################
resource "aws_route53_resolver_rule_association" "reverse-10" {
  depends_on = ["aws_route53_resolver_rule.reverse-10"]
  count = "${length(var.associated-vpc-ids)}"
  resolver_rule_id = "${aws_route53_resolver_rule.reverse-10.id}"
  vpc_id           = "${var.associated-vpc-ids[count.index]}"
}
resource "aws_route53_resolver_rule_association" "forward-lavrichev-com" {
  depends_on = ["aws_route53_resolver_rule.forward-lavrichev-com"]
  count = "${length(var.associated-vpc-ids)}"
  resolver_rule_id = "${aws_route53_resolver_rule.forward-factset-com.id}"
  vpc_id           = "${var.associated-vpc-ids[count.index]}"
}
