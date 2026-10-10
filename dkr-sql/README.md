# SQL Server 2022: escenario de producción

Este Compose ejecuta SQL Server y un contenedor de respaldos. Trabaja siempre desde `dkr-sql/`; no hay un Compose global en la raíz del repositorio.

## Requisitos antes de desplegar

- Host Linux `amd64` con recursos suficientes para SQL Server 2022, Docker Engine y Compose; licencia válida para la edición indicada por `MSSQL_PID`. No utilices la edición Developer para producción.
- Una IP **del host** para `SQL_BIND_IP` y un firewall/VPN que permita TCP 1433 **solo a clientes autorizados**. Compose no filtra por IP de origen; no publiques este puerto directamente a Internet.
- Certificado TLS válido para el nombre usado por los clientes: configura SQL Server para cifrar conexiones y usa clientes con verificación del certificado. `-C` en el contenedor de backups solo confía en el certificado de la conexión interna de Docker; no es la configuración adecuada para clientes externos.
- Almacenamiento persistente: `./data/sqlserver/sql_data` conserva datos; `SQL_BACKUP_PATH` debe ser una **ruta absoluta**, fuera de `./data/sqlserver/sql_data`, en un disco con espacio disponible. La imagen SQL Server 2022 utilizada corre como `mssql` (UID **10001**, GID **10001**): ambas carpetas montadas deben permitirle escritura (en este host: propietario `grusso`, grupo `10001`, modo `770`). El contenedor de backups necesita poder leer y borrar respaldos antiguos. Verifica la identidad efectiva al cambiar de imagen y no cambies recursivamente permisos de datos existentes.
- Prepara un destino externo al host (otro servidor o almacenamiento remoto) y replica allí los `.bak`. La retención local no protege contra pérdida del servidor.

## Configuración

Crea o ajusta `dkr-sql/.env` en el host. El archivo local existente se retiró del índice de Git, pero **sus valores anteriores siguen en el historial**: rota esas credenciales antes de producción. No subas valores nuevos a Git. Usa `.env.example` solo como lista de variables. Comprueba en particular los valores existentes de `SQL_BACKUP_PATH` (debe ser absoluto) y `SQL_SERVER` (el backup usa el servicio interno `sqlserver`, independientemente del valor anterior).

Selecciona una imagen SQL Server 2022 compatible y fíjala por digest para evitar cambios imprevistos; establece `SQL_IMAGE` en `.env`. `MSSQL_PID` debe corresponder a tu licencia. La contraseña de `sa` se toma de `SA_PASSWORD`; `SQL_USER` debe ser `sa` o un usuario con permiso de backup cuya contraseña coincida con `SA_PASSWORD`. `SQL_DB` identifica **una** base de datos (solo letras, números, `_` y `-`): las demás bases no se respaldan con este escenario.

```bash
cd dkr-sql
docker compose config --quiet
docker compose build sql-backup
docker compose up -d
docker compose ps
```

`config --quiet` valida la sintaxis y las variables obligatorias, no los permisos ni las conexiones. `sql-backup` espera a que el puerto SQL acepte conexiones; esto no comprueba que la base configurada exista ni que el usuario tenga permisos. **Crea o restaura `SQL_DB` antes de dar por operativo el backup**. Revisa los logs de ambos contenedores tras el arranque.

## Respaldo y recuperación

La tarea diaria corre a las **02:00 UTC**. SQL Server escribe el `.bak` directamente en `/var/opt/mssql/backups`, que corresponde a `SQL_BACKUP_PATH` en el host; después se ejecuta `RESTORE VERIFYONLY WITH CHECKSUM`. Si falla, se elimina el archivo incompleto. Tras un respaldo correcto se borran archivos de esa base con más de `BACKUP_RETENTION_DAYS` días (predeterminado: 7). Esto solo respalda la base indicada por `SQL_DB`, no bases de sistema, claves, certificados ni otras bases.

```bash
# Ejecutar un respaldo sin esperar al cron; falla si ya hay uno en curso.
docker compose exec sql-backup /usr/local/bin/backup.sh
docker compose logs --tail=100 sql-backup
```

`VERIFYONLY` no reemplaza una restauración real. Antes de considerar el servicio operativo, restaura periódicamente una copia **en una instancia aislada** y valida la aplicación contra ella; no hagas la prueba sobre la base productiva. Conserva fuera del host al menos una copia recuperable y verifica que la tarea programada realmente se ejecute. Al actualizar, toma un backup verificado y planifica la ventana de mantenimiento; nunca uses `docker compose down -v` para esta instancia.

## Acceso remoto

Conéctate a `SQL_BIND_IP:1433` desde las IP autorizadas por el firewall/VPN. El bind a una IP del host no reemplaza el firewall. Configura el cliente para cifrar y **verificar** el certificado (`Encrypt=True`, `TrustServerCertificate=False`); no uses `TrustServerCertificate=True` para ocultar un fallo de TLS. El Compose no instala ni renueva certificados ni configura el firewall del host: esas tareas deben completarse antes de abrir el acceso remoto.

### Conexión mediante túnel SSH desde Linux

Si tienes acceso SSH al servidor, puedes publicar SQL solo en el loopback del **servidor** (`SQL_BIND_IP=127.0.0.1`) y conectar desde otra máquina sin exponer TCP 1433 en la red. Ejecuta en la máquina **cliente** y deja la terminal abierta; `-v` muestra detalles para diagnosticar fallos:

```bash
ssh -v -N -o ExitOnForwardFailure=yes \
  -L '127.0.0.1:1433:127.0.0.1:1433' grusso@192.168.0.84
```

Conecta tu cliente SQL a `127.0.0.1,1433` **en tu máquina**. El primer `1433` del túnel es el puerto local: si ya está ocupado, cámbialo por `1143` (`-L '127.0.0.1:1143:127.0.0.1:1433'`) y conecta a `127.0.0.1,1143`. El último `127.0.0.1:1433` se interpreta **en el servidor SSH**: funciona si `SQL_BIND_IP=127.0.0.1` o `0.0.0.0`; si el puerto está publicado solo en `192.168.0.84`, usa `-L '127.0.0.1:1433:192.168.0.84:1433'`. El túnel cifra el trayecto SSH, pero un cliente SQL que verifique TLS puede necesitar configurar el nombre del certificado del servidor, ya que se conecta a `localhost`; no desactives la verificación del certificado como solución permanente.

## Diagnóstico de arranque y backups

Ejecuta estos comandos desde `dkr-sql/`. No compartas la salida completa de `docker compose config`: puede mostrar la contraseña; usa `--quiet`.

### Faltan variables al ejecutar `docker compose up -d`

Si Compose informa que faltan `SQL_IMAGE`, `MSSQL_PID` o `SQL_BIND_IP`, completa **tu** `.env` siguiendo `.env.example`: imagen 2022 fijada por digest, edición con licencia e IP asignada al servidor. Comprueba también que `SQL_BACKUP_PATH` sea absoluto y `SA_PASSWORD` sea una clave privada nueva. Después:

```bash
docker compose config --quiet
docker compose up -d
```

### `sqlserver` aparece como `unhealthy` o se reinicia

```bash
docker compose ps -a
docker compose logs --tail=80 sqlserver
stat -c '%a %u:%g %n' ./data/sqlserver/sql_data /ruta/absoluta/de/backups
```

Sustituye `/ruta/absoluta/de/backups` por el valor de `SQL_BACKUP_PATH`. Si el log indica `The system directory [/.system] could not be created` y `Permission denied`, comprueba primero la escritura en los montajes: la imagen usada aquí ejecuta `mssql` como **10001:10001**; `grusso:root` con `770` **no** le da acceso, aunque el grupo sea `root`. Si tu imagen mantiene ese UID/GID, en un despliegue nuevo o con permisos previamente verificados:

```bash
docker compose stop sqlserver
sudo chgrp 10001 ./data/sqlserver/sql_data /ruta/absoluta/de/backups
sudo chmod 770 ./data/sqlserver/sql_data /ruta/absoluta/de/backups
docker compose up -d
docker compose ps
```

Los comandos actúan **solo sobre esas dos carpetas**, no recursivamente sobre archivos de una instalación existente. Si ya hay datos, o cambiaste la imagen/usuario, inspecciona también propietarios y permisos de los archivos antes de modificarlos. No uses `chmod 777` ni borres `data/` para resolver este error. Un estado `healthy` confirma el chequeo de puerto, **no** que los backups funcionen.

### SQL inicia, pero `SQL_DB` todavía no existe

El contenedor `sql-backup` puede estar en marcha sin que exista la base indicada en `.env`. Consulta las bases mediante el cliente interno, sin imprimir la contraseña:

```bash
docker compose exec -T sql-backup bash -c 'source /run/sqlbackup.env; export SQLCMDPASSWORD="$SA_PASSWORD"; /opt/mssql-tools18/bin/sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -C -b -l 30 -Q "SELECT name FROM sys.databases"'
```

Si `SQL_DB` no aparece, créala o restaúrala **según tus datos reales**; no cambies `SQL_DB` por una base de sistema solo para silenciar el error. Una vez disponible, ejecuta `docker compose exec sql-backup /usr/local/bin/backup.sh`, comprueba `docker compose logs --tail=100 sql-backup` y que se haya creado el `.bak` en `SQL_BACKUP_PATH`. Finalmente prueba una restauración en otra instancia. Hasta entonces, el respaldo automático no está validado.
