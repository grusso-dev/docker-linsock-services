# docker-linsock-services

Este repositorio contiene una colección de servicios y configuraciones Docker orientados a facilitar el despliegue y la gestión de aplicaciones que requieren comunicación eficiente mediante sockets en entornos Linux.

## ¿Qué realiza este repositorio?
- Proporciona ejemplos y plantillas para levantar servicios Dockerizados que utilizan sockets para la comunicación entre contenedores o con el sistema anfitrión.
- Permite experimentar y probar configuraciones de red y comunicación entre servicios en un entorno controlado.
- Es útil como base para desarrolladores que desean crear soluciones basadas en microservicios o sistemas distribuidos usando Docker y sockets en Linux.

---

## Organización típica de servicios dockerizados

Un proyecto con servicios dockerizados suele tener la siguiente estructura:

```
.
├── docker-compose.yml   # Archivo principal para definir y orquestar los servicios
├── servicio1/           # Carpeta con Dockerfile y configuración de un servicio
├── servicio2/           # Carpeta con Dockerfile y configuración de otro servicio
└── ...
```

Cada carpeta de servicio puede contener su propio `Dockerfile`, archivos de configuración y scripts necesarios.

## Estructura del proyecto

La siguiente vista rápida muestra la organización real de carpetas de este repositorio:

```text
docker-linsock-services/
├── dkr-ftp/
│   └── docker-compose.yml
├── dkr-php/
│   ├── docker-compose.yml
│   ├── data/
│   │   └── nginx/
│   │       └── default.conf
│   └── php/
│       └── dockerfile
├── dkr-sql/
│   ├── docker-compose.yml
│   └── backup/
│       ├── Dockerfile
│       ├── backup.sh
│       └── crontab.txt
├── comands.txt
└── README.md
```

---

## ¿Cómo levantar los servicios?

1. **Clona este repositorio:**
   ```zsh
   git clone https://github.com/grusso-dev/docker-linsock-services.git
   cd docker-linsock-services
   ```

2. **Asegúrate de tener Docker y Docker Compose instalados en tu sistema.**

3. **Levanta los servicios:**
   ```zsh
   docker compose up -d
   ```
   Esto construirá y levantará todos los servicios definidos en el archivo `docker-compose.yml` en modo desatendido (background).

4. **Verifica que los servicios estén corriendo:**
   ```zsh
   docker compose ps
   ```

5. **Para detener los servicios:**
   ```zsh
   docker compose down
   ```

---

## Personalización y ampliación

- Puedes agregar nuevos servicios creando nuevas carpetas y agregando sus respectivos `Dockerfile` y configuraciones.
- Modifica el archivo `docker-compose.yml` para incluir o ajustar los servicios según tus necesidades.

---

## Servicios incluidos

A continuación se describen los grupos de contenedores presentes en este repositorio y su propósito.

### dkr-ftp

Contiene una instancia de **vsftpd** configurada para exponer un usuario de FTP sencillo. El volumen principal se toma de la ruta definida en la variable `PHP_APP_PATH` para compartir archivos con otros contenedores. Las variables de entorno `FTP_USER`, `FTP_PASS` y `PASV_*` permiten ajustar las credenciales y el rango de puertos pasivos.

### dkr-php

Incluye un contenedor con PHP-FPM basado en Alpine y un contenedor Nginx como servidor web. La imagen de PHP se construye con un `Dockerfile` que instala extensiones comunes y soporte para SQL Server. El código de la aplicación se monta desde `PHP_APP_PATH` y Nginx publica el puerto **8080** del host.

### dkr-sql

Proporciona Microsoft SQL Server 2022 junto con un contenedor auxiliar para realizar copias de seguridad automáticas mediante **cron**. Se utilizan las variables `SA_PASSWORD`, `SQL_USER`, `SQL_DB`, `SQL_SERVER` y `SQL_BACKUP_PATH` para configurar la autenticación y la ubicación de los archivos de respaldo.

---

## Uso de variables de entorno

Todos los archivos de composición leen sus parámetros desde un archivo `.env` ubicado en la raíz del proyecto. A continuación se muestra un ejemplo básico:

```env
PHP_APP_PATH=/ruta/a/tu/aplicacion
SQL_BACKUP_PATH=/ruta/para/backups
SA_PASSWORD=TuPasswordSegura
SQL_USER=usuario
SQL_DB=base_de_datos
SQL_SERVER=sqlserver
```

Crea este archivo antes de levantar los servicios para personalizar rutas y credenciales.
