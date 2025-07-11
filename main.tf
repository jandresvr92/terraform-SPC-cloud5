# --- Red (VPC) --- 
resource "aws_vpc" "main" { 
  cidr_block = var.vpc_cidr_block 
  enable_dns_hostnames = true 

  tags = { 
    Name = "${var.project_name}-VPC-cloud5" 
  } 
} 

resource "aws_subnet" "public" { 
  vpc_id                  = aws_vpc.main.id 
  cidr_block              = var.public_subnet_cidr_block 
  map_public_ip_on_launch = true 
  availability_zone       = "${var.aws_region}a" 

  tags = { 
    Name = "${var.project_name}-PublicSubnet-cloud5" 
  } 
} 

resource "aws_internet_gateway" "main" { 
  vpc_id = aws_vpc.main.id 

  tags = { 
    Name = "${var.project_name}-IGW-cloud5" 
  } 
} 

resource "aws_route_table" "public" { 
  vpc_id = aws_vpc.main.id 

  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.main.id 
  } 

  tags = { 
    Name = "${var.project_name}-PublicRouteTable-cloud5" 
  } 
} 

resource "aws_route_table_association" "public" { 
  subnet_id      = aws_subnet.public.id 
  route_table_id = aws_route_table.public.id 
} 

resource "aws_security_group" "frontend_sg" { 
  name        = "${var.project_name}-Frontend-SG" 
  description = "Permitir trafico HTTP HTTPS y SSH al frontend" 
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

  ingress {
    description = "Frontend app en puerto 5173"
    from_port   = 5173
    to_port     = 5173
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
    Name = "${var.project_name}-Frontend-SG-cloud5" 
  } 
} 

resource "aws_security_group" "backend_sg" { 
  name        = "${var.project_name}-Backend-SG" 
  description = "Permitir trafico desde cualquier lugar y SSH al backend" 
  vpc_id      = aws_vpc.main.id 

  ingress { 
    description = "SSH desde cualquier lugar" 
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 

  # CORREGIDO: Permitir tráfico desde cualquier IP, no solo desde el frontend SG
  ingress { 
    description = "API del backend desde cualquier lugar" 
    from_port   = 3001 
    to_port     = 3001 
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
    Name = "${var.project_name}-Backend-SG-cloud5" 
  } 
} 

# Crear el backend primero para obtener su IP
resource "aws_instance" "backend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_backend 
  subnet_id     = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.backend_sg.id] 
  key_name      = var.key_pair_name 

  user_data = filebase64("${path.module}/scripts/backend-init.sh")
  
  tags = { 
    Name    = "${var.project_name}-BackendInstance-cloud5" 
    Purpose = "Backend" 
  } 
} 

# Crear el frontend después del backend y pasar la IP del backend
resource "aws_instance" "frontend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_frontend 
  subnet_id     = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.frontend_sg.id] 
  key_name      = var.key_pair_name 

  # Usar template para pasar la IP del backend al frontend
  user_data = base64encode(templatefile("${path.module}/scripts/frontend-init.sh", {
    backend_ip = aws_instance.backend_instance.public_ip
  }))

  # Asegurar que el backend esté creado antes del frontend
  depends_on = [aws_instance.backend_instance]

  tags = { 
    Name    = "${var.project_name}-FrontendInstance-cloud5" 
    Purpose = "Frontend" 
  } 
} 