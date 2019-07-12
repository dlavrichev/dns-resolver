# dns-resolver

## Table of contents
* [Description](#description)
* [Current list of resolver rules](#current-list-of-resolver-rules)
* [How to use this modle](#how-to-use-this-modle)

## Description
This script creates a Route53 resolver (using Terraform module stored in github) in the existing VPC. This is used when a VPC has Amazon provided DNS and still needs to perform DNS resolution for local DNS zones that are not present within Route 53. Resolver endpoint must be present in at least 2 availability zones or have 2 IP addresses within the same subnet. Security group, needed for this resolver also gets created here. Then all necessary resolver rules get created. Once all the rules are in place, the resource share is being created as well and can be shared with another account or OU.Once it is shared, all VPC are associated with these resolver rules

## Current list of resolver rules
* 10.in-addr.arpa. reverse lookup zone.
* lavrichev.com. forward zone.

## How to use this module
This module will require terraform version 0.12.1
Generally, Resolver gets installed once per region. Resolver must be created in existing VPC. Resolver endpoint must have at least 2 IP addresses. They can belong to a single subnet (AZ) or be in different AZs for redundancy. Script also allowes to choose which IPs should be assigned to endpoint in each AZ ('endpoint-ips' variable is used for this purpose.)

In main.tf file, should look like this. All main.tf versions should be stored in this repo for later re-use if new resolver rules must
be added.

```

terraform {
  # s3 bucket is used to store terraform state for later modifications
  backend "s3" {
    bucket = "tfstate-bucket"
    key = "network/dns-resolver/terraform.tfstate"
    region = "us-east-1"
  }

}
provider "aws" {
  region = "<destination region>"
}

module "dns-resolver" {
  source = "git::https://github.com/dlavrichev/dns-resolver.git"

environment = "prod"
team_name = "network"

# Region where resolver is being setup
region = "us-east-1"

#  VPC where resolver will reside
vpc-id = "vpc-xxxxxxxxxxxxxxxx"

# Subnet(s) where resolver endpoint is present
subnet-ids = ["subnet-xxxxxxxxxxxxxx","subnet-yyyyyyyyyyyyyyy"]
#keep in mind that 'endpoint-ips' should be in the same corresponding subnet from 'subnet-ids'
endpoint-ips = ["10.10.5.250","10.10.6.250"]

# List of VPCs that need to be associated (in other words, need to be able to resolve internal DNS)
associated-vpc-ids = ["vpc-xxxxxxxxxxxxxx","vpc-yyyyyyyyyyyyy","vpc-zzzzzzzzzzzzz"]

#below is the list of IPs of DNS servers that used as forwarders
forwarders = ["10.10.1.250","10.10.2.250"]

tags = {
	"Environment" = "prod"
  }
}
```
