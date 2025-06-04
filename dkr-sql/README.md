# dkr-sql

Incluye la configuración para ejecutar Microsoft SQL Server 2022 junto con un contenedor auxiliar de copias de seguridad.

- **sqlserver**: contenedor oficial que expone el puerto **1433**.
- **sql-backup**: utiliza los scripts en `backup/` para generar respaldos automáticos mediante cron.

Las credenciales y rutas se definen en el archivo `.env`, que contiene variables como `SA_PASSWORD`, `SQL_USER`, `SQL_DB`, `SQL_SERVER` y `SQL_BACKUP_PATH`.

## Estructura

```
dkr-sql/
├── docker-compose.yml  # define SQL Server y contenedor de respaldo
├── backup/
│   ├── Dockerfile  # imagen para las tareas de backup
│   ├── backup.sh   # script que realiza las copias
│   └── crontab.txt # programación de cron
└── README.md
```

Esta estructura organiza tanto el contenedor principal de SQL Server como el servicio auxiliar encargado de las copias de seguridad automáticas.

## Uso

1. Ajusta las variables del archivo `.env`.
2. Levanta los servicios con:
   ```bash
   docker compose up -d
   ```
   Esto iniciará `sqlserver` y el servicio de backup.

