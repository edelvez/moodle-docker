# Restore runbook

Este procedimiento restaura Moodle desde backups generados por `scripts/backup.sh`.

## Requisitos

- Acceso a los contenedores/servicios del stack.
- Backup de PostgreSQL (`postgres-<timestamp>.sql.gz`).
- Backup de datos (`moodledata-<timestamp>.tar.gz`).

## Procedimiento

1. Detener `moodle` y `cron`.
2. Restaurar base de datos PostgreSQL.
3. Restaurar volumen `moodledata`.
4. Levantar `moodle` y `cron`.
5. Validar login, cursos, subida de archivo y ejecucion de cron.

## Comandos de referencia

Detener servicios de aplicacion:

```bash
docker compose -f compose.coolify.yml stop moodle cron
```

Restaurar base de datos:

```bash
gunzip -c /ruta/postgres-YYYYMMDDTHHMMSSZ.sql.gz | docker compose -f compose.coolify.yml exec -T postgres psql -U "$MOODLE_DATABASE_USER" -d "$MOODLE_DATABASE_NAME"
```

Restaurar `moodledata`:

```bash
docker compose -f compose.coolify.yml run --rm -v moodle_moodledata:/bitnami/moodledata -v /ruta:/restore alpine sh -c "rm -rf /bitnami/moodledata/* && tar -xzf /restore/moodledata-YYYYMMDDTHHMMSSZ.tar.gz -C /bitnami"
```

Levantar servicios:

```bash
docker compose -f compose.coolify.yml up -d moodle cron
```

## Validacion final

- Acceso web y login admin correctos.
- Cursos y archivos disponibles.
- `docker compose -f compose.coolify.yml logs cron` muestra ejecucion periodica.
