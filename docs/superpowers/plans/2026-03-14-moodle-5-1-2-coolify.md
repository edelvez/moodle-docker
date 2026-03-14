# Moodle 5.1.2 en Coolify Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Desplegar Moodle 5.1.2 en produccion sobre Coolify como stack de servicios (Moodle, PostgreSQL, Redis, cron y backups) con version fija, persistencia local y configuracion segura.

**Architecture:** Se usara una imagen Docker custom basada en Bitnami pinneada a Moodle 5.1.2. El despliegue se define en un compose orientado a Coolify con red interna y volumenes persistentes locales para DB y `moodledata`. Se agregan servicios operativos separados para cron y backup diario con retencion.

**Tech Stack:** Docker, Docker Compose (Coolify), Moodle 5.1.2 (base Bitnami), PostgreSQL, Redis, Bash scripting.

---

## Chunk 1: Estructura base del proyecto

### Task 1: Crear estructura y contratos de configuracion

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`
- Create: `.env.example`
- Create: `compose.coolify.yml`
- Create: `docs/operations/README-moodle-stack.md`

- [ ] **Step 1: Crear `.dockerignore` minimo**

```dockerignore
.git
.gitignore
node_modules
vendor
tmp
.env
backups
```

- [ ] **Step 2: Crear `.env.example` con variables requeridas**

```env
MOODLE_IMAGE_TAG=5.1.2
MOODLE_HOST=moodle.midominio.com
MOODLE_DATABASE_NAME=moodle
MOODLE_DATABASE_USER=moodle
MOODLE_DATABASE_PASSWORD=change_me
POSTGRES_PASSWORD=change_me
REDIS_PASSWORD=change_me
MOODLE_ADMIN_USERNAME=admin
MOODLE_ADMIN_PASSWORD=change_me
MOODLE_ADMIN_EMAIL=admin@example.com
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=user
SMTP_PASSWORD=change_me
BACKUP_RETENTION_DAYS=7
```

- [ ] **Step 3: Crear `docs/operations/README-moodle-stack.md`**

Incluir: prerequisitos, como cargar secretos en Coolify, orden de despliegue, runbook de restauracion.

- [ ] **Step 4: Validar que no haya secretos reales en archivos**

Run: `rg "(password=|PASSWORD=|SECRET=)" .env.example docs/operations/README-moodle-stack.md -n`
Expected: solo placeholders (`change_me`), ningun secreto real.

- [ ] **Step 5: Commit**

```bash
git add .dockerignore .env.example docs/operations/README-moodle-stack.md
git commit -m "chore: define env contract and deployment docs for moodle stack"
```

## Chunk 2: Imagen custom de Moodle 5.1.2

### Task 2: Construir imagen pinneada y reproducible

**Files:**
- Modify/Create: `Dockerfile`
- Test: `Dockerfile` (build + runtime smoke test)

- [ ] **Step 1: Escribir prueba de aceptacion de build (comando esperado)**

Run: `docker build -t moodle:5.1.2-local .`
Expected: build exitoso con base Bitnami y sin usar `latest`.

- [ ] **Step 2: Implementar `Dockerfile` minimo y pinneado**

```dockerfile
FROM bitnami/moodle:5.1.2

USER root
RUN install_packages tzdata curl
USER 1001
```

- [ ] **Step 3: Ejecutar build para verificar que pasa**

Run: `docker build -t moodle:5.1.2-local .`
Expected: PASS, imagen creada.

- [ ] **Step 4: Ejecutar smoke test de runtime**

Run: `docker run --rm moodle:5.1.2-local /opt/bitnami/scripts/moodle/run.sh --help`
Expected: comando responde sin error fatal.

- [ ] **Step 5: Commit**

```bash
git add Dockerfile
git commit -m "build: add pinned moodle 5.1.2 image based on bitnami"
```

## Chunk 3: Stack Compose para Coolify

### Task 3: Definir servicios `moodle`, `postgres`, `redis`, `cron`

**Files:**
- Create/Modify: `compose.coolify.yml`
- Test: `compose.coolify.yml`

- [ ] **Step 1: Escribir validacion de sintaxis compose**

Run: `docker compose -f compose.coolify.yml config`
Expected: PASS, YAML normalizado sin errores.

- [ ] **Step 2: Implementar servicios base en `compose.coolify.yml`**

Definir:
- `postgres` con volumen `postgres_data`.
- `redis` con password y red interna.
- `moodle` con volumen `moodledata`, dependencias y healthcheck.
- `cron` con misma imagen de `moodle` y comando de cron cada minuto.

- [ ] **Step 3: Implementar red y volumenes persistentes**

Agregar red interna y volumenes:
- `postgres_data`
- `moodledata`

- [ ] **Step 4: Verificar levantado local del stack**

Run: `docker compose -f compose.coolify.yml up -d postgres redis`
Expected: DB y Redis en estado healthy o running.

Run: `docker compose -f compose.coolify.yml up -d moodle cron`
Expected: Moodle accesible y cron en ejecucion.

- [ ] **Step 5: Commit**

```bash
git add compose.coolify.yml
git commit -m "feat: add coolify stack for moodle postgres redis and cron"
```

## Chunk 4: Backups y recuperacion

### Task 4: Crear servicio de backup diario con retencion

**Files:**
- Create: `scripts/backup.sh`
- Create/Modify: `compose.coolify.yml`
- Create: `docs/operations/restore.md`
- Test: `scripts/backup.sh`

- [ ] **Step 1: Escribir prueba de comando de backup esperado**

Run: `bash scripts/backup.sh`
Expected: genera dump de PostgreSQL y archivo comprimido de `moodledata` en carpeta `backups/`.

- [ ] **Step 2: Implementar `scripts/backup.sh`**

Incluir:
- `pg_dump` contra `postgres`
- `tar` para `moodledata`
- nombres con timestamp UTC
- retencion por `BACKUP_RETENTION_DAYS`
- salida con codigo de error no-cero ante fallo

- [ ] **Step 3: Integrar servicio `backup` en compose**

Agregar servicio con:
- montaje de `moodledata`
- acceso a `postgres`
- carpeta persistente `backups`
- scheduler (cron interno o bucle sleep 24h) segun patron elegido

- [ ] **Step 4: Documentar restauracion en `docs/operations/restore.md`**

Incluir restore completo:
1) detener moodle/cron
2) restaurar DB
3) restaurar `moodledata`
4) levantar servicios y validar login

- [ ] **Step 5: Commit**

```bash
git add scripts/backup.sh compose.coolify.yml docs/operations/restore.md
git commit -m "feat: add automated backup and restore runbook"
```

## Chunk 5: Verificacion final de produccion

### Task 5: Ejecutar checklist funcional y de seguridad

**Files:**
- Modify: `docs/operations/README-moodle-stack.md`
- Test: stack running state

- [ ] **Step 1: Verificar estado de servicios**

Run: `docker compose -f compose.coolify.yml ps`
Expected: `moodle`, `postgres`, `redis`, `cron`, `backup` arriba.

- [ ] **Step 2: Verificar cron y conectividad DB/cache**

Run: `docker compose -f compose.coolify.yml logs cron`
Expected: ejecucion periodica de `cron.php` sin errores criticos.

- [ ] **Step 3: Verificar backup generado**

Run: `docker compose -f compose.coolify.yml logs backup`
Expected: backup diario exitoso y politica de retencion aplicada.

- [ ] **Step 4: Registrar resultados en runbook**

Actualizar `docs/operations/README-moodle-stack.md` con:
- fecha de validacion
- resultado de cada check
- observaciones de hardening pendientes

- [ ] **Step 5: Commit**

```bash
git add docs/operations/README-moodle-stack.md
git commit -m "docs: record production verification checklist results"
```

## Notas de calidad

- DRY: usar variables compartidas y evitar duplicar secretos.
- YAGNI: no agregar observabilidad avanzada ni S3 en esta iteracion.
- TDD adaptado a infraestructura: cada bloque se valida con comandos que deben fallar/pasar segun el paso.
- Commits frecuentes por chunk para rollback limpio.
