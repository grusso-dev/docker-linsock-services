#!/bin/bash
set -Eeuo pipefail

: "${SQL_SERVER:?}"
: "${SQL_DB:?}"
: "${SQL_USER:?}"
: "${SA_PASSWORD:?}"
: "${BACKUP_RETENTION_DAYS:?}"

# Los nombres pasan por una consulta SQL y por rutas de archivo.
[[ "$SQL_DB" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo 'SQL_DB debe contener solo letras, numeros, _ o -' >&2; exit 1; }
[[ "$BACKUP_RETENTION_DAYS" =~ ^[0-9]+$ ]] && (( BACKUP_RETENTION_DAYS >= 1 )) || {
    echo 'BACKUP_RETENTION_DAYS debe ser un entero positivo' >&2; exit 1;
}

# No se escriben secretos en el crontab ni en los logs.
umask 077
declare -p SQL_SERVER SQL_DB SQL_USER SA_PASSWORD BACKUP_RETENTION_DAYS > /run/sqlbackup.env
exec cron -f
