variable "region" {
  description = "Region, where VPC is be created"
  default     = "us-east-1"
}
variable "environment" {
  description = "Account environment type (should be one of dev, prod, uat or sandbox)"
  default     = "dev"
}
variable "team_name" {
  description = "Name of SBU or team that will support resources in this account.  For enterprise hosting, should be three letter customer identifier"
  default     = ""
}
variable "vpc-id" {
  description = "VPC ID"
  default     = ""
}
variable "subnet-ids" {
  description = "A Subnet IDs where resolver endpoint exists. At least 2 subnets must exist"
  default     = []
}
variable "endpoint-ips" {
  description = "These are the preferred list of IPs to be assigned to endpoint in the corresponding subnet from 'subnet-ids'"
  default     = []
}
variable "associated-vpc-ids" {
  description = "A list VPCs that resolver rules will be associated with"
  default     = []
}
variable "forwarders" {
  description = "A list of DNS servers used as forwarders for internal DNS resolution"
  default     = ["10.10.1.250","10.10.2.250"]
}
variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
