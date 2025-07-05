# Terraform AWS Free Tier Setup

Este proyecto crea una infraestructura básica en AWS usando Terraform, dentro del Free Tier, que incluye:

- Una VPC con 2 subredes públicas (us-east-1a y us-east-1b)
- Una tabla de ruteo e internet gateway
- Una instancia EC2 Ubuntu pública (t2.micro)
- Una base de datos RDS MySQL (db.t3.micro) accesible desde la EC2

## 🛠 Requisitos

- Cuenta AWS con Free Tier habilitado
- Terraform instalado (v1.0+)
- Key Pair existente en EC2 con archivo `.pem` descargado

## 🧾 Estructura del proyecto

