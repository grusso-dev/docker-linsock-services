# dkr-php

Este directorio contiene la configuración necesaria para levantar un entorno PHP con Nginx utilizando Docker Compose.

- **php**: se construye desde `php/Dockerfile` e instala PHP-FPM 8.4 con extensiones comunes y soporte para SQL Server.
- **nginx**: sirve la aplicación y expone el puerto **8080** en el host.

El código de tu aplicación se monta en `/var/www` dentro de los contenedores usando la variable `PHP_APP_PATH` definida en el archivo `.env` local.

## Estructura

```
dkr-php/
├── docker-compose.yml  # orquesta los servicios PHP y Nginx
├── php/
│   └── dockerfile      # imagen personalizada con extensiones
├── data/
│   └── nginx/
│       └── default.conf  # configuración de Nginx
└── README.md
```

Estos archivos permiten construir la imagen de PHP, configurar Nginx y levantar el entorno completo con Docker Compose.

## Uso

1. Ajusta la ruta `PHP_APP_PATH` en `.env` para que apunte al directorio de tu aplicación.
2. Ejecuta:
   ```bash
   docker compose up -d
   ```
   Esto iniciará los contenedores `php` y `nginx`.

