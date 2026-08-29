# dkr-php

Este directorio contiene la configuración necesaria para levantar un entorno PHP con Nginx utilizando Docker Compose.

- **php**: se construye desde `php/Dockerfile` e instala PHP-FPM 8.4 con extensiones comunes y soporte para SQL Server.
- **nginx**: sirve la aplicación y expone el puerto **8080** en el host.

La imagen PHP incluye Bash para scripts de aplicación, Composer 2.10.2 para administrar dependencias bajo demanda y las herramientas `sqlcmd`/`bcp` de SQL Server disponibles en el `PATH`.

Las aplicaciones se montan desde las rutas `PHP_APP_PATH_DEV` y `PHP_APP_PATH_PRD` definidas en el archivo `.env` local. Cada variable debe apuntar a la raíz completa de la aplicación, no a su directorio `public`.

## Estructura

```
dkr-php/
├── docker-compose.yml  # orquesta los servicios PHP y Nginx
├── RECOMENDACIONES.md  # mejoras propuestas todavía no aplicadas
├── php/
│   └── Dockerfile      # imagen personalizada con extensiones
├── data/
│   └── nginx/
│       └── default.conf  # configuración de Nginx
└── README.md
```

Estos archivos permiten construir la imagen de PHP, configurar Nginx y levantar el entorno completo con Docker Compose.

Las optimizaciones evaluadas pero todavía no aplicadas se documentan en [RECOMENDACIONES.md](RECOMENDACIONES.md).

## Requisitos de plataforma

Este entorno utiliza contenedores Linux AMD64 debido a las dependencias de Microsoft ODBC incluidas en la imagen PHP.

Plataformas soportadas:

- Linux con procesador Intel/AMD de 64 bits.
- Windows con procesador Intel/AMD de 64 bits, Docker Desktop, WSL2 y contenedores Linux.

ARM64 no está soportado oficialmente por este proyecto. En un host ARM, Docker puede intentar ejecutar PHP mediante emulación porque Compose declara `platform: linux/amd64`, pero ese escenario queda fuera del alcance soportado.

## Uso

1. Ajusta `PHP_APP_PATH_HME`, `PHP_APP_PATH_DEV` y `PHP_APP_PATH_PRD` en `.env`. Las rutas DEV y PRD deben apuntar a la raíz de cada aplicación.
2. Ejecuta:
   ```bash
   docker compose up -d
   ```
   Esto iniciará los contenedores `php` y `nginx`.

## Uploads

Las aplicaciones pueden guardar archivos en `storage/app/uploads`. Nginx los publica como contenido estático mediante estas rutas:

- DEV: `http://localhost:8080/lskdev/uploads/<archivo>`
- PRD: `http://localhost:8080/lskprd/uploads/<archivo>`

Nginx monta las aplicaciones como solo lectura y rechaza archivos con extensiones PHP dentro de estas rutas. La aplicación sigue siendo responsable de validar el tamaño, el tipo y el nombre de cada archivo subido.

## Estado de los servicios

PHP-FPM y Nginx tienen healthchecks y una política `restart: unless-stopped`. Nginx espera a que PHP-FPM esté saludable antes de iniciar. El estado HTTP de Nginx se puede consultar en:

```text
http://localhost:8080/health
```

Una respuesta `200 OK` con el texto `ok` confirma que Nginx está activo. El estado detallado de ambos contenedores puede consultarse con `docker compose ps`.
