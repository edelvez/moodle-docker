# Diseno: Stack Docker Moodle 5.1.2 para produccion en Coolify

## Contexto

Se requiere un despliegue de Moodle en produccion usando Coolify, con arquitectura tipo stack de servicios, version fija de Moodle 5.1.2, persistencia local para `moodledata`, cache con Redis y backups automaticos.

## Objetivos

- Desplegar Moodle 5.1.2 con imagen fija y reproducible.
- Separar responsabilidades por servicio (web, DB, cache, cron, backup).
- Garantizar persistencia de datos y recuperacion ante fallos.
- Mantener una base operable para produccion sin complejidad excesiva inicial.

## Decisiones tomadas

- Base de imagen: Bitnami (recomendada).
- Version Moodle: fija en 5.1.2.
- Tipo de despliegue: stack de servicios en Coolify.
- Base de datos: PostgreSQL.
- Cache/sesiones: Redis habilitado.
- Almacenamiento de archivos Moodle: volumen local (`moodledata`).
- Backups: automaticos, diarios, con retencion.

## Enfoques evaluados

1. Imagen custom minima + stack completo (recomendado).
2. Imagen upstream sin customizacion (menor control).
3. Stack con observabilidad/operacion avanzada desde el dia 1 (mayor complejidad).

Se selecciona el enfoque 1 por equilibrio entre robustez, control y simplicidad operativa.

## Arquitectura del stack

Servicios:

- `moodle`: contenedor principal con imagen custom basada en Bitnami, pinneada a 5.1.2.
- `postgres`: servicio dedicado para base de datos con volumen persistente.
- `redis`: servicio de cache/sesiones, solo red interna.
- `cron`: contenedor separado (misma imagen de Moodle) para ejecutar `cron.php` cada minuto.
- `backup`: job/servicio para respaldo diario de PostgreSQL y `moodledata`.

Volumenes:

- `moodledata` (local persistente).
- `postgres_data` (local persistente).

Red:

- Red interna privada para `moodle`, `postgres`, `redis`, `cron`, `backup`.
- Solo `moodle` expuesto publicamente a traves de Coolify con HTTPS.

## Configuracion de produccion

### Imagen y versionado

- Prohibido `latest`.
- Tag fijo `5.1.2` para Moodle.
- Recomendado pin adicional por digest cuando sea posible.

### Secretos

Definir en Coolify (no hardcodear en compose):

- `MOODLE_DATABASE_PASSWORD`
- `REDIS_PASSWORD`
- `MOODLE_ADMIN_PASSWORD`
- Credenciales SMTP

### Seguridad base

- Sin privilegios extra en contenedores.
- `no-new-privileges` donde aplique.
- Exposicion publica solo de `moodle`.
- `postgres` y `redis` accesibles unicamente por red interna.
- Healthchecks activos para `moodle`, `postgres`, `redis`.

### Operacion

- `cron` separado para ejecucion regular de tareas Moodle.
- Backups diarios con retencion sugerida: 7 diarios + 4 semanales.
- Prueba periodica de restauracion para validar recuperacion real.

## Flujo de despliegue en Coolify

1. Build de imagen custom de Moodle 5.1.2.
2. Levantar `postgres` y `redis`.
3. Levantar `moodle`.
4. Levantar `cron`.
5. Ejecutar instalacion inicial de Moodle con PostgreSQL + Redis.
6. Activar y verificar job de backup.

## Estrategia de actualizacion

- Sin auto-upgrade de version mayor/menor.
- Actualizaciones mediante nueva imagen versionada y despliegue controlado.
- Rollback usando tag anterior validado.

## Manejo de fallos

- Reinicio automatico para `moodle` ante fallo.
- Aislamiento de servicios de datos en red privada.
- Recuperacion desde backup en caso de corrupcion/perdida.

## Checklist de validacion post-despliegue

- Login de administrador correcto.
- Ejecucion de cron confirmada.
- Redis activo como cache/sesiones.
- Carga y descarga de archivos en `moodledata`.
- Backup diario generado y restauracion de prueba exitosa.

## Fuera de alcance por ahora

- Observabilidad avanzada (Prometheus/Grafana/exporters dedicados).
- Almacenamiento de objetos externo (S3/MinIO/R2).
- Escalado horizontal multi-nodo.

## Criterios de exito

- Plataforma estable en produccion con servicios separados.
- Datos persistentes y respaldados.
- Capacidad de rollback y recuperacion validada.
- Operacion diaria predecible en Coolify.
