provider "aws" {
  region = "us-east-1"
}

# -------------------
# VPC
# -------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# -------------------
# Internet Gateway
# -------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# -------------------
# Subnets
# -------------------
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

# -------------------
# Route Table & Association
# -------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------
# Security Groups
# -------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL from EC2"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# -------------------
# RDS MySQL (Free Tier)
# -------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "mysql_db" {
  identifier              = "wolf-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "wolfpassword123"
  db_name                 = "inventory_db"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = true
  skip_final_snapshot     = true
  multi_az                = false

  tags = {
    Name = "wolf-mysql-db"
  }
}

# -------------------
# EC2 Instance (Web Server)
# -------------------
resource "aws_instance" "ubuntu_server" {
  ami                         = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io docker-compose git mysql-client
              systemctl enable docker
              systemctl start docker

              # Clonar el repositorio con la app
              git clone https://github.com/marioJRDZGarcia/openaiterraformwolf.git /opt/app
              cd /opt/app/app

              # Variables de entorno para Flask
              echo "DB_HOST=${aws_db_instance.mysql_db.endpoint}" > .env
              echo "DB_USER=admin" >> .env
              echo "DB_PASS=wolfpassword123" >> .env
              echo "DB_NAME=inventory_db" >> .env

              # Esperar a que RDS esté lista
              sleep 60
              mysql -h ${aws_db_instance.mysql_db.endpoint} -u admin -pwolfpassword123 -e "CREATE TABLE IF NOT EXISTS inventory_db.inventory (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), quantity INT);"

              # Levantar contenedor Flask
              docker-compose up -d
              EOF

  tags = {
    Name = "ubuntu-server"
  }
}

# -------------------
# Outputs
# -------------------
output "ec2_public_ip" {
  value = aws_instance.ubuntu_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql_db.endpoint
}
