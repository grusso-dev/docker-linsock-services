#!/bin/bash

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/backups/${SQL_DB}_${DATE}.bak"

/opt/mssql-tools/bin/sqlcmd -S ${SQL_SERVER} -U ${SQL_USER} -P ${SA_PASSWORD} -Q "BACKUP DATABASE [${SQL_DB}] TO DISK = N'${BACKUP_FILE}' WITH NOFORMAT, INIT, NAME = 'Full Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
