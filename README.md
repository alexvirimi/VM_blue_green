# VM_blue_green

## Contexto

Una empresa quiere disminuir el tiempo de indisponibilidad al actualizar una aplicación  contenerizada.

- **Plataforma:** AWS.
- **Herramientas:** Terraform, Ansible y Nginx.

## Actividades mínimas

- Crear con Terraform una máquina virtual en AWS.
- Configurarla mediante Ansible.
- Ejecutar dos versiones de la aplicación, azul y verde.
- Utilizar Nginx como proxy inverso.
- Construir y analizar la nueva imagen desde Github Actions.
- Desplegar una nueva versión en el ambiente inactivo y verificar el endpoint de salud.
- Cambiar a Nginx hacia la versión nueva solamente si la verificación es exitosa.
- Mantener una forma sencilla de regresar a la versión anterior.

## Demostración requerida

La demostración deberá incluir un despliegue exitoso y una explicación del mecanismo de rollback.

## Evidencias de equipo

El equipo deberá presentar el repositorio, la ejecución de los workflows, la aplicación publicada, los resultados de seguridad y una explicación breve de las decisiones de infraestructura.
