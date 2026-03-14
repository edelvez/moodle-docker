# Moodle 5.0.2 Stack for Coolify

Este directorio describe la operacion de un stack de Moodle 5.0.2 para produccion en Coolify.

## Servicios

- `moodle`: aplicacion web Moodle (imagen preconstruida Bitnami Legacy 5.0.2).
- `postgres`: base de datos PostgreSQL 16.
- `redis`: cache/sesiones.
- `cron`: ejecucion de `admin/cli/cron.php` cada minuto.
- `backup`: respaldo diario de base de datos y `moodledata` con retencion.

## Archivos clave

- `Dockerfile`
- `compose.coolify.yml`
- `.env.example`
- `scripts/backup.sh`
- `docs/operations/restore.md`

## Variables y secretos

Copiar `.env.example` a `.env` y cargar valores reales en Coolify como secretos.

Variables obligatorias:

- `MOODLE_HOST`
- `MOODLE_DATABASE_NAME`
- `MOODLE_DATABASE_USER`
- `MOODLE_DATABASE_PASSWORD`
- `MOODLE_ADMIN_USERNAME`
- `MOODLE_ADMIN_PASSWORD`
- `MOODLE_ADMIN_EMAIL`
- `REDIS_PASSWORD`

Opcionales recomendadas:

- `MOODLE_SMTP_*`
- `BACKUP_RETENTION_DAYS`

## Despliegue en Coolify

1. Crear servicio Docker Compose y apuntar a `compose.coolify.yml`.
2. Cargar secretos/variables desde `.env` en el panel de Coolify.
3. Desplegar primero `postgres` y `redis`.
4. Desplegar `moodle`.
5. Confirmar acceso web.
6. Desplegar `cron` y `backup`.

## Validaciones post-despliegue

- `moodle` responde por HTTP/HTTPS.
- `postgres` y `redis` en estado healthy.
- `cron` ejecuta tareas cada minuto.
- `backup` genera archivos en volumen `backups`.

## Nota sobre Redis

La pila incluye Redis y variables para conexion. Dependiendo de ajustes internos de Moodle/imagen, puede requerirse ajuste adicional en `config.php` para usar Redis como cache de aplicacion. Mantener esta verificacion en el checklist funcional.
