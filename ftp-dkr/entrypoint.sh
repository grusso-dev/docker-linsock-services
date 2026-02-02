#!/bin/sh
set -e

FTP_USER=${FTP_USER:-grusso}
FTP_HOME="/home/vsftpd/${FTP_USER}"

# Si la carpeta existe, ajustamos permisos
if [ -d "$FTP_HOME" ]; then
    echo "🔧 Ajustando permisos en $FTP_HOME ..."
    chown -R ftp:ftp "$FTP_HOME"
    chmod -R 755 "$FTP_HOME"
else
    echo "⚠️ No existe $FTP_HOME, se creará al iniciar vsftpd"
fi

exec "$@"
