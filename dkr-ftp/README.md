# dkr-ftp

Configuración de un servidor FTP sencillo basado en **vsftpd**.

El contenedor expone el puerto estándar 21 y un rango de puertos pasivos para facilitar la conexión desde clientes externos. Los valores de usuario y contraseña, así como el directorio compartido, se definen en el archivo `.env` y en el `docker-compose.yml`.

La variable `PHP_APP_PATH` indica la ruta que se montará como raíz del usuario FTP.

## Estructura

```
dkr-ftp/
├── docker-compose.yml  # define el servicio vsftpd y sus variables
└── README.md           # documentación del contenedor
```

Cada archivo cumple el rol de describir y orquestar el contenedor FTP.

## Uso

1. Edita `.env` y ajusta `PHP_APP_PATH` según tu proyecto.
2. Ejecuta:
   ```bash
   docker compose up -d
   ```
   El contenedor `ftp` quedará listo para aceptar conexiones.

