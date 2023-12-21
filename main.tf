resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr_block
    instance_tenancy = "default" 

        tags = {
        Name = "Dev-VPC"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main"
    }
}

resource "aws_subnet" "public-subnets" {
    count = length(var.subnet_cidr_block)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.subnet_cidr_block, count.index)
    availability_zone = element(var.availability_zone, count.index)
    map_public_ip_on_launch = true

    tags = {
        Name = element(var.public_subnets, count.index)
    }
  
}

resource "aws_subnet" "private-subnets" {
    count = length(var.subnet_cidr_block)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.private_subnet_cidr_block, count.index)
    availability_zone = element(var.private_availability_zone, count.index)
    map_public_ip_on_launch = false

    tags = {
        Name = element(var.private_subnets, count.index)

    }
}

resource aws_route_table "public_route_table" {
  count = length(var.public_route_table)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    name = element(var.public_route_table, count.index)
  }
}

resource aws_route_table "private_route_table" {
  count = length(var.private_route_table)
  vpc_id = aws_vpc.main.id
  
  tags = {
    name = element(var.private_route_table, count.index)
  }


}

resource "aws_route_table_association" "main" {
  count = 2
  subnet_id      = element(aws_subnet.public-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
}


resource "aws_route_table_association" "main2" {
  count = 2
  subnet_id      = element(aws_subnet.private-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

resource "aws_nat_gateway" "natgw" {
  count = length(var.private_subnets)
  subnet_id = element(aws_subnet.public-subnets.*.id, count.index)
  allocation_id = element(aws_eip.nat-gw.*.id, count.index)

  tags = {
    Name =  "private-natgateway-${count.index}"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat-gw" {
  count = 2 #lenght(var.private_subnets)
  vpc = true
}
   

resource "aws_lb_target_group" "dev" {
  name     = "devtrain"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  vpc_id      = aws_vpc.main.id

  
  ingress {
    description      = "public_traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "my_public_ip"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["80.193.62.172/32"]
  }

  ingress {
    description      = "public_traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
 
}

resource "aws_launch_template" "launch_tmp" {
    name_prefix = "devtrainlt"
    image_id = "ami-0505148b3591e4c07"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    key_name = "DevOps-Key"
    user_data = filebase64("bootstrap.sh")

}

resource "aws_autoscaling_group" "asg" {
  capacity_rebalance  = true
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = aws_subnet.public-subnets.*.id

launch_template {
    id      = aws_launch_template.launch_tmp.id
    version = aws_launch_template.launch_tmp.latest_version
  }

  }

resource "aws_lb" "main" {
    load_balancer_type = "application"
    subnets = [for subnet in aws_subnet.public-subnets : subnet.id]
    security_groups = [aws_security_group.allow_tls.id]
}

resource "aws_lb_listener" "front_end" {
    load_balancer_arn =aws_lb.main.arn
    port ="443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn = aws_acm_certificate.cert.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.dev.arn
    }
}

data "aws_route53_zone" "public" {
    name = "firsttechconsultants.co.uk"
    private_zone = false
}


resource "aws_acm_certificate" "cert" {
    domain_name = "*.firsttechconsultants.co.uk"
    validation_method = "DNS"
    subject_alternative_names = ["deji.firsttechconsultants.co.uk"]

    lifecycle {
         create_before_destroy = true
    }
}


resource "aws_route53_record" "validation" {
    for_each = {
        for x in aws_acm_certificate.cert.domain_validation_options : x.domain_name => {
        name = x.resource_record_name
        record = x.resource_record_value
        type = x.resource_record_type
        zone_id = x.domain_name == "firsttechconsultants.co.uk" ? data.aws_route53_zone.public.zone_id : data.aws_route53_zone.public.zone_id
        }
    }
    allow_overwrite = true 
    name = each.value.name
    records = [each.value.record]
    ttl = 300
    type = each.value.type
    zone_id = "Z0128271FTR80TWSFUX3"

}



resource "aws_route53_record" "www" {
    zone_id = "Z0128271FTR80TWSFUX3"
    name = "deji.firsttechconsultants.co.uk"
    type = "A"

    alias {
        name =aws_lb.main.dns_name
        zone_id = aws_lb.main.zone_id
        evaluate_target_health = true
    }
    
}

resource "aws_launch_template" "main" {
    
    name_prefix = "dejilt"
    image_id = "ami-0505148b3591e4c07"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    key_name = "DevOps-Key"
    user_data = filebase64("bootstrap.sh")
}

resource "aws_autoscaling_attachment" "main" {
    autoscaling_group_name = aws_autoscaling_group.asg.id
    lb_target_group_arn    = aws_lb_target_group.dev.arn


}





 

 




