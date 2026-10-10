#!/bin/bash
set -Eeuo pipefail

# Cron no hereda las variables de Compose; el entrypoint las guarda en /run.
source /run/sqlbackup.env
export SQLCMDPASSWORD="$SA_PASSWORD"

exec 9>/run/sqlbackup.lock
flock -n 9 || { echo 'Ya hay otro backup en curso' >&2; exit 1; }

DATE=$(date -u +'%Y%m%d_%H%M%S_%N')
BACKUP_FILE="/var/opt/mssql/backups/${SQL_DB}_${DATE}.bak"
HOST_FILE="/backups/${SQL_DB}_${DATE}.bak"

# El motor SQL, no sqlcmd, escribe el archivo; ambos contenedores montan la misma ruta.
cleanup() {
    rm -f -- "$HOST_FILE"
}
trap cleanup ERR

/opt/mssql-tools18/bin/sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -C -b -l 30 \
    -Q "BACKUP DATABASE [${SQL_DB}] TO DISK = N'${BACKUP_FILE}' WITH COMPRESSION, CHECKSUM, STATS = 10"
/opt/mssql-tools18/bin/sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -C -b -l 30 \
    -Q "RESTORE VERIFYONLY FROM DISK = N'${BACKUP_FILE}' WITH CHECKSUM"

trap - ERR
find /backups -maxdepth 1 -type f -name "${SQL_DB}_*.bak" \
    -mmin "+$((BACKUP_RETENTION_DAYS * 1440))" -delete
echo "Backup verificado: ${HOST_FILE}"
