provider "aws"{
  region  = "us-east-1"
}


resource "aws_instance" "example"{
  ami = "ami-06b5810be11add0e2"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.example.id}"]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello World!" > index.html
    nohup busybox httpd -f -p "${var.server_port}" &
    EOF

  tags{
    Name = "terraform-example"
    env = "dev"
  }
}


#security group
resource "aws_security_group" "example"{
  name = "allow 8080"

  ingress{
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    from_port = "22"
    to_port = "22"
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port"{
  description="instance webserver port to run on"
  default = "8080"
}
