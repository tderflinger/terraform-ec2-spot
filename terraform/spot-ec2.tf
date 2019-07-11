# Provisions a spot EC2 instance with Centos 7.4 image
# Zone for AMI is us-east-1

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test-env" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet-uno" {
  # creates a subnet
  cidr_block        = "${cidrsubnet(aws_vpc.test-env.cidr_block, 3, 1)}"
  vpc_id            = "${aws_vpc.test-env.id}"
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "ingress-ssh-test" {
  name   = "allow-ssh-sg"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-http-test" {
  name   = "allow-http-sg"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-https-test" {
  name   = "allow-https-sg"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_spot_instance_request.test_worker.spot_instance_id}"
  vpc      = true
}

resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${aws_vpc.test-env.id}"
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = "${aws_vpc.test-env.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-env-gw.id}"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet-uno.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}

resource "aws_key_pair" "spot_key" {
  key_name   = "spot_key"
  public_key = "${file("/home/xx/.ssh/id_rsa.pub")}"
}

resource "aws_spot_instance_request" "test_worker" {
  ami                    = "ami-66a7871c"
  spot_price             = "0.016"
  instance_type          = "t3.small"
  spot_type              = "one-time"
  block_duration_minutes = "120"
  wait_for_fulfillment   = "true"
  key_name               = "spot_key"

  security_groups = ["${aws_security_group.ingress-ssh-test.id}", "${aws_security_group.ingress-http-test.id}",
  "${aws_security_group.ingress-https-test.id}"]
  subnet_id = "${aws_subnet.subnet-uno.id}"
}
