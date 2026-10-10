# Guía para agentes

- Este repositorio reúne escenarios Docker independientes, no un stack único. No hay `docker-compose.yml` en la raíz: ejecuta `docker compose` desde la carpeta del escenario; sus variables `.env` están en esas carpetas, no en la raíz como indica el README general.
- Valida la configuración sin imprimir credenciales: `cd dkr-sql && docker compose config --quiet` (sustituye la carpeta para otros escenarios). Prioriza Compose y scripts sobre los README cuando discrepen.
- `dkr-sql/docker-compose.yml` declara `sqlserver` y `sql-backup` (backup diario de una sola base a las 02:00 UTC). La imagen de backups se construye localmente; sin prueba real de restauración y copia fuera del host no consideres validada la recuperación.
- El escenario SQL es **solo producción**, con consultas desde otras máquinas. `SQL_BIND_IP` limita la interfaz del host, no las IP de origen: el firewall/VPN, el certificado TLS y el digest de la imagen deben configurarse antes de abrir acceso remoto.
- Los `.env` de `dkr-ftp` y `dkr-php` siguen versionados aunque `.gitignore` los excluya para archivos nuevos; `dkr-sql/.env` se retiró del índice, pero sus valores anteriores permanecen en el historial. No reproduzcas secretos de `.env`, configuraciones ni PHP en respuestas o documentación.
- `dkr-slm-bas/docker-compose.override.yml` se aplica automáticamente al iniciar su Compose base. Si se combina explícitamente el base con `docker-compose.prod.yml`, las listas de puertos se acumulan y se publican **58080 y 80**; verifica el resultado con `docker compose config`.
- `ftp-dkr/entrypoint.sh` aplica `chown -R` y `chmod -R` al directorio montado del host en cada arranque: no lo ejecutes sobre archivos existentes sin evaluar el impacto.
