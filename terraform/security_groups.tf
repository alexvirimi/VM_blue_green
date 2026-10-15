resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Permite HTTP publico; la administracion se realiza mediante AWS Systems Manager."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP publico para la aplicacion del taller"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP para repositorios Ubuntu que aun usan HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS para ECR, paquetes y actualizaciones"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = {
    Name = "${var.project_name}-default-deny-sg"
  }
}
