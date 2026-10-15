# Ansible: configuración y despliegue blue/green

## Estructura

```
ansible/
├── ansible.cfg
├── requirements.yml              # colecciones de Ansible necesarias
├── .ansible-lint
├── inventory/
│   └── hosts.yml.example         # copiar a hosts.yml y cambiar las variables
│   └── group_vars/
│       └── all.yml                   # variables (puertos, límites, health check)
├── playbooks/
│   ├── setup.yml                 # instala Docker y Nginx
│   ├── demo.yml                  # prueba con contenedores sustitutos
│   ├── switch.yml                # cambia el color activo
│   ├── deploy.yml                # despliegue real desde ECR
│   └── rollback.yml              # vuelve al color anterior
└── roles/
    ├── common/                   # Docker, AWS CLI, directorio de estado
    ├── nginx/                    # Nginx, plantilla y handler de reload
    └── bluegreen/                # deploy, rollback, switch, health check
```

## Requisitos previos

**Máquina de control**
- Linux, macOS o WSL con Ansible instalado (paso 1).
- Colección `community.docker` (`ansible-galaxy collection install -r requirements.yml` en el paso 1).

**Máquina virtual (creada con Terraform)**
- AWS EC2 con Ubuntu 22.04 (los roles usan `apt`) y usuario `ubuntu`.
- Security Group: puerto 22 abierto desde su IP y puerto 80 público.
- Salida a internet por el puerto 443 (paquetes e imágenes).
- Rol IAM con permiso de pull en ECR (para el despliegue real).

**Acceso**
- Llave SSH del key pair de la VM, con permisos `400`.
- IP pública de la VM.
- Para el despliegue real: URL del repositorio ECR y tag de una imagen ya publicada.

## Instrucciones de uso

### 1. Instalar Ansible y las colecciones
 
```bash
sudo apt update && sudo apt install -y pipx
pipx install --include-deps ansible
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### 2. Obtener la IP de la máquina virtual
Desde la carpeta `terraform/`, ejecute:
```bash
terraform output -raw vm_public_ip
```

### 3. Crear el inventario
 
```bash
cp inventory/hosts.yml.example inventory/hosts.yml
```
 
Edite `inventory/hosts.yml`:
 
```yaml
all:
  hosts:
    vm1:
      ansible_host: <IP_DE_LA_VM>
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/<su-llave>.pem
```
 
### 4. Verificar la conexión
 
```bash
ssh -i ~/.ssh/<su-llave>.pem ubuntu@<IP_DE_LA_VM>    # debe entrar
ansible all -i inventory/hosts.yml -m ping           # debe responder pong
```

### 5. Configurar la máquina virtual (Docker + Nginx)
 
```bash
ansible-playbook -i inventory/hosts.yml playbooks/setup.yml
```
 
Una segunda ejecución debe mostrar `changed=0`.
 
Comprobación en la VM:
 
```bash
docker --version
systemctl status nginx
```
Si no se tiene docker se deben ejecutar los siguientes comandos:

```bash
sudo apt update
sudo apt install -y docker.io ansible
sudo apt install -y nginx
```

### 6. Probar el mecanismo blue/green con contenedores demo

Antes de utilizar la aplicación real, para estar seguro de que todo funciona o en caso de no tener disponible ECR podemos realizar un demo.
Este demo sustituye a la aplicación real mientras no esté disponible en ECR. Levanta `app-blue` y `app-green` con una imagen pública y deja Nginx apuntando a blue.
 
```bash
ansible-playbook -i inventory/hosts.yml playbooks/demo.yml
curl -i http://<IP_DE_LA_VM>/
```
Debe responder "Hola mundo desde BLUE" con el header `X-Active-Color: blue`.

### 7. Cambiar de color
 
```bash
ansible-playbook -i inventory/hosts.yml playbooks/switch.yml -e target_color=green
curl -i http://<IP_DE_LA_VM>/        # X-Active-Color: green
 
ansible-playbook -i inventory/hosts.yml playbooks/switch.yml -e target_color=blue
curl -i http://<IP_DE_LA_VM>/        # X-Active-Color: blue
```

### 8. Despliegue real desde ECR
 
Requiere que la imagen ya esté publicada en ECR (la publica el workflow de CI/CD).
 
```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml \
  -e ecr_repository_url=<cuenta>.dkr.ecr.<region>.amazonaws.com/<repositorio> \
  -e image_tag=<sha-del-commit>
```

El ECR es inmutable: use el SHA del commit como `image_tag`, no `latest`.
 
Flujo interno:
 
1. Lee el color activo (`/opt/bluegreen/active_color`) y elige el inactivo como destino.
2. Inicia sesión en ECR con el rol IAM de la instancia.
3. Levanta la imagen nueva en el color inactivo.
4. Verifica `GET /health` con reintentos (hasta 15, cada 2 s).
5. Si responde 200: valida con `nginx -t`, recarga Nginx y guarda el estado.
6. Si falla: apaga el contenedor nuevo, aborta y Nginx no se toca.
El primer despliegue parte sin color activo y se instala en blue.

### 9. Rollback
 
```bash
ansible-playbook -i inventory/hosts.yml playbooks/rollback.yml
curl -i http://<IP_DE_LA_VM>/        # vuelve el color anterior
```
 
El deploy no apaga el color anterior, por lo que el rollback solo reapunta Nginx: verifica que el contenedor anterior responde, cambia el proxy y recarga. No descarga imágenes ni reinicia contenedores.
**Limitación:** el rollback retrocede un solo paso. Tras dos despliegues seguidos, la versión original ya no está disponible.
 
Si desea revisar el estado de la máquina virtual:
Revisar el estado en la VM:
 
```bash
docker ps
cat /opt/bluegreen/active_color /opt/bluegreen/previous_color
sudo nginx -t
```

## Decisiones
 
- **Roles en lugar de un playbook plano**: `common`, `nginx` y `bluegreen` se reutilizan entre playbooks; el cambio de Nginx está escrito en un único lugar (`switch.yml`).
- **Estado en archivos de la VM**: el color activo y el anterior se guardan en `/opt/bluegreen`, sin base de datos externa.
- **`reload` en lugar de `restart`**: Nginx recarga la configuración sin cortar conexiones activas.
