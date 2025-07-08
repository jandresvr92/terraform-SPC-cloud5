# --- Red (VPC) --- 
resource "aws_vpc" "main" { 
  cidr_block = var.vpc_cidr_block 
  enable_dns_hostnames = true 

  tags = { 
    Name = "${var.project_name}-VPC" 
  } 
} 

resource "aws_subnet" "public" { 
  vpc_id                  = aws_vpc.main.id 
  cidr_block              = var.public_subnet_cidr_block 
  map_public_ip_on_launch = true 
  availability_zone       = "${var.aws_region}a" 

  tags = { 
    Name = "${var.project_name}-PublicSubnet" 
  } 
} 

resource "aws_internet_gateway" "main" { 
  vpc_id = aws_vpc.main.id 

  tags = { 
    Name = "${var.project_name}-IGW" 
  } 
} 

resource "aws_route_table" "public" { 
  vpc_id = aws_vpc.main.id 

  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.main.id 
  } 

  tags = { 
    Name = "${var.project_name}-PublicRouteTable" 
  } 
} 

resource "aws_route_table_association" "public" { 
  subnet_id      = aws_subnet.public.id 
  route_table_id = aws_route_table.public.id 
} 

resource "aws_security_group" "frontend_sg" { 
  name        = "${var.project_name}-Frontend-SG" 
  description = "Permitir tráfico HTTP/HTTPS y SSH al frontend" 
  vpc_id      = aws_vpc.main.id 

  ingress { 
    description = "SSH desde cualquier lugar" 
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 

  ingress { 
    description = "HTTP desde cualquier lugar" 
    from_port   = 80 
    to_port     = 80 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 

  ingress { 
    description = "HTTPS desde cualquier lugar" 
    from_port   = 443 
    to_port     = 443 
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
    Name = "${var.project_name}-Frontend-SG" 
  } 
} 

resource "aws_security_group" "backend_sg" { 
  name        = "${var.project_name}-Backend-SG" 
  description = "Permitir tráfico desde el frontend y SSH al backend" 
  vpc_id      = aws_vpc.main.id 

  ingress { 
    description = "SSH desde cualquier lugar" 
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 

  ingress { 
    description     = "Tráfico de aplicación desde el frontend" 
    from_port       = 3000 
    to_port         = 3000 
    protocol        = "tcp" 
    security_groups = [aws_security_group.frontend_sg.id] 
  } 

  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 

  tags = { 
    Name = "${var.project_name}-Backend-SG" 
  } 
} 

resource "aws_instance" "frontend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_frontend 
  subnet_id     = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.frontend_sg.id] 
  key_name      = var.key_pair_name 

  user_data = ""

  tags = { 
    Name    = "${var.project_name}-FrontendInstance" 
    Purpose = "Frontend" 
  } 
} 

resource "aws_instance" "backend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_backend 
  subnet_id     = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.backend_sg.id] 
  key_name      = var.key_pair_name 

  user_data = ""

  tags = { 
    Name    = "${var.project_name}-BackendInstance" 
    Purpose = "Backend" 
  } 
} 