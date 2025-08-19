################################################
## imports
################################################
## vpc
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.namespace}-poc-vpc"]
  }
}


data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = var.vpc_name != null ? [var.vpc_name] : ["${var.namespace}-${var.environment}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
data "aws_kms_key" "sns" {
  key_id = "alias/aws/sns"
}
