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

  lifecycle{
    create_before_destroy = true
  }
}


resource "aws_launch_configuration" "as_conf"{
  name =  "web_config"
  image_id =  "ami-06b5810be11add0e2"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.example.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World!" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle{
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "as_grp"{
  launch_configuration =  "${aws_launch_configuration.as_conf.id}"
  load_balancers =  ["${aws_elb.ex_elb.name}"]
  health_check_type = "ELB"
  min_size  = 2
  max_size  = 10
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  tag{
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

data "aws_availability_zones" "all" {

}


resource "aws_elb" "ex_elb"{
  name =  "sample-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  listener{
    lb_port =  80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"

  }

  health_check{
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb_sg"{
  name = "elb_sg_sample"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}



variable "server_port"{
  description="instance webserver port to run on"
  default = "8080"
}

output "elb_dns_name" {
  value = "${aws_elb.ex_elb.dns_name}"
}
