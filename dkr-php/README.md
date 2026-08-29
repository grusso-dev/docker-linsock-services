# dkr-php

Entorno Docker para ejecutar producción y staging como dos parejas PHP-FPM/Nginx aisladas.

## Arquitectura

| Entorno | URL desde el host | Servicio Nginx | Servicio PHP | Código dentro de PHP | Red interna |
| --- | --- | --- | --- | --- | --- |
| Producción | `http://localhost:8080/lskprd/` | `nginx-production` | `php-production` | `/var/www/lskprd` | `production-network` |
| Staging | `http://localhost:8081/lskdev/` | `nginx-staging` | `php-staging` | `/var/www/lskdev` | `staging-network` |

`nginx-production` publica el puerto 8080 y `nginx-staging` publica el 8081. Los servicios PHP-FPM sólo declaran `expose: 9000`: el puerto 9000 es accesible dentro de su red Docker, pero no queda publicado en el host ni en la red local.

El aislamiento funciona de la siguiente manera:

- `php-production` sólo monta el código de producción y sólo pertenece a `production-network`.
- `php-staging` sólo monta el código de staging y sólo pertenece a `staging-network`.
- `nginx-production` sólo monta la página principal y producción como solo lectura, y depende únicamente de `php-production`.
- `nginx-staging` sólo monta staging como solo lectura, y depende únicamente de `php-staging`.
- El puerto 8080 rechaza `/lskdev` y el puerto 8081 rechaza `/lskprd`.
- Staging envía `X-Robots-Tag: noindex, nofollow, noarchive`. Esta cabecera no reemplaza la autenticación ni las reglas de firewall.

Se ejecutan cuatro contenedores: dos PHP-FPM y dos Nginx. Si staging falla durante el arranque o su Nginx tiene una configuración inválida, la pareja de producción puede continuar disponible.

## Variantes disponibles

Hay dos archivos Compose que implementan la misma arquitectura y usan las configuraciones `data/nginx/production.conf` y `data/nginx/staging.conf`:

| Archivo | Imagen PHP | Uso sugerido |
| --- | --- | --- |
| `docker-compose.yml` | PHP 8.4 sobre Alpine 3.24 | Opción predeterminada y más compacta para equipos con pocos recursos |
| `docker-compose.debian.yml` | PHP 8.4 sobre Debian 13 Trixie | Mayor compatibilidad con herramientas o dependencias que esperan Debian/glibc |

No deben levantarse ambas variantes simultáneamente porque las dos intentan publicar los puertos 8080 y 8081.

Todos los comandos de este documento que muestran `docker compose` sin `-f` corresponden a Alpine. Si elegiste Debian, conserva `-f docker-compose.debian.yml` en cada comando de administración, por ejemplo `docker compose -f docker-compose.debian.yml ps`.

Ambas imágenes consumen la lista común `php/extensions.txt`: `bcmath`, `ds`, `exif`, `fileinfo`, `gd`, `intl`, `mbstring`, `opcache`, `pcntl`, `pdo_sqlsrv`, `redis`, `sqlsrv` y `zip`. Elegir Alpine o Debian cambia el sistema operativo base, pero no las extensiones PHP declaradas por el proyecto.

Para agregar o quitar una extensión, modifica únicamente `php/extensions.txt`, reconstruye ambas variantes y comprueba los requisitos de la aplicación con `composer check-platform-reqs`.

## Requisitos

- Docker Engine con Docker Compose v2 en Linux, o Docker Desktop con WSL2 y contenedores Linux en Windows.
- Procesador Intel/AMD de 64 bits.
- Puertos 8080 y 8081 libres en el host.
- Acceso a Internet durante el primer build para descargar imágenes, paquetes y dependencias de Microsoft.

El proyecto declara `platform: linux/amd64` debido a los componentes ODBC de Microsoft. ARM64 no está soportado oficialmente; para macOS ARM se preparará un proyecto separado.

## Estructura esperada de las aplicaciones

Cada variable de `.env` debe apuntar a la raíz completa correspondiente, no directamente a `public`.

```text
homepage/
└── index.html

lskprd/
├── public/
│   └── index.php
└── storage/
    └── app/
        └── uploads/

lskdev/
├── public/
│   └── index.php
└── storage/
    └── app/
        └── uploads/
```

Las carpetas `storage/app/uploads` sólo son obligatorias si las aplicaciones utilizan la ruta de uploads configurada. Otros directorios de escritura, como cachés o logs, dependen del framework.

## Configurar `.env`

El repositorio incluye `.env.example` como plantilla, pero `.env` es local y está ignorado por Git. Esto permite usar rutas y tags diferentes en cada servidor sin modificar archivos versionados ni exponer accidentalmente credenciales futuras.

En Linux, macOS o WSL2, crea la copia local con:

```bash
cp .env.example .env
```

En PowerShell:

```powershell
Copy-Item .env.example .env
```

Después edita `.env`. El archivo controla qué carpetas del host se montan y qué imágenes PHP utiliza cada entorno:

```dotenv
PHP_APP_PATH_HME=/opt/web/homepage
PHP_APP_PATH_PRD=/opt/web/lskprd
PHP_APP_PATH_DEV=/var/lsk/grn_sysdev
PHP_IMAGE_PRODUCTION_TAG=1.0.0
PHP_IMAGE_STAGING_TAG=1.1.0-rc1
```

No agregues `.env` al repositorio. Si en el futuro contiene contraseñas, tokens o claves, deben permanecer únicamente en la instalación local o trasladarse a un mecanismo específico de secretos.

| Variable | Contenido | Acceso desde Nginx | Acceso desde PHP |
| --- | --- | --- | --- |
| `PHP_APP_PATH_HME` | Página principal estática | Sólo lectura | No se monta |
| `PHP_APP_PATH_PRD` | Aplicación de producción | Sólo lectura | Lectura y escritura en `php-production` |
| `PHP_APP_PATH_DEV` | Aplicación de staging | Sólo lectura | Lectura y escritura en `php-staging` |

Los tags `PHP_IMAGE_PRODUCTION_TAG` y `PHP_IMAGE_STAGING_TAG` controlan qué versión del runtime PHP usa cada entorno. El Compose Alpine genera imágenes `dkr-php-alpine:<tag>` y el Compose Debian genera `dkr-php-debian:<tag>`, evitando mezclar imágenes construidas sobre sistemas base diferentes.

Usa tags nuevos e inmutables para cada candidato, por ejemplo `1.2.0-rc1`. No reutilices un tag que ya haya sido aprobado porque dificultaría comprobar qué imagen está ejecutándose y volver a una versión anterior.

### Ejemplo para Linux

```dotenv
PHP_APP_PATH_HME=/srv/linsock/homepage
PHP_APP_PATH_PRD=/srv/linsock/lskprd
PHP_APP_PATH_DEV=/srv/linsock/lskdev
```

Las rutas deben existir antes de iniciar Compose. En Linux, el usuario utilizado por PHP-FPM debe poder escribir en los directorios que necesiten uploads, caché o logs. Es preferible asignar propietario, grupo o ACL adecuados en lugar de usar permisos globales como `chmod 777`.

### Ejemplo para Windows

Si Docker Compose se ejecuta desde PowerShell o CMD con Docker Desktop:

```dotenv
PHP_APP_PATH_HME=C:/linsock/homepage
PHP_APP_PATH_PRD=C:/linsock/lskprd
PHP_APP_PATH_DEV=C:/linsock/lskdev
```

Si el comando se ejecuta dentro de WSL2, utiliza rutas visibles desde WSL:

```dotenv
PHP_APP_PATH_HME=/mnt/c/linsock/homepage
PHP_APP_PATH_PRD=/mnt/c/linsock/lskprd
PHP_APP_PATH_DEV=/mnt/c/linsock/lskdev
```

Usa barras `/` y verifica que Docker Desktop tenga permiso para compartir la unidad o carpeta seleccionada.

## Configuración requerida en cada aplicación

Separar contenedores y puertos no es suficiente si ambas aplicaciones comparten configuración interna.

### URL base y subcarpeta

Configura cada aplicación para operar bajo su prefijo:

- Producción: `http://IP_O_HOST:8080/lskprd`
- Staging: `http://IP_O_HOST:8081/lskdev`

El framework debe generar enlaces, redirecciones y assets conservando `/lskprd` o `/lskdev`. Si se configura la aplicación como si viviera en `/`, las redirecciones o archivos CSS/JavaScript pueden apuntar a una dirección incorrecta.

### Sesiones y cookies

Las cookies se aíslan por dominio y ruta, pero no por puerto. Aunque 8080 y 8081 sean puertos diferentes, configura:

- nombres de cookie distintos para producción y staging;
- `Path=/lskprd/` en producción;
- `Path=/lskdev/` en staging;
- atributos `HttpOnly` y `SameSite` apropiados.

Si posteriormente se habilita HTTPS, agrega también `Secure`.

### Datos y credenciales

Producción y staging deben utilizar de forma independiente:

- bases de datos y usuarios de base de datos;
- contraseñas y secretos;
- claves de cifrado de la aplicación;
- almacenamiento de sesiones y caché;
- credenciales de correo, APIs y otros servicios externos.

Este stack incluye los controladores y herramientas para conectarse a SQL Server, pero no levanta un servidor SQL Server. La dirección y las credenciales se configuran dentro de cada aplicación.

## Puesta en marcha

Ejecuta los comandos desde el directorio `dkr-php`.

### Alpine, variante predeterminada

Validar la configuración resuelta:

```bash
docker compose config
```

Primera construcción e inicio:

```bash
docker compose build php-production php-staging
docker compose up -d
```

### Debian

Validar la configuración resuelta:

```bash
docker compose -f docker-compose.debian.yml config
```

Primera construcción e inicio:

```bash
docker compose -f docker-compose.debian.yml build php-production php-staging
docker compose -f docker-compose.debian.yml up -d
```

Para cambiar de variante, primero detén la que está activa con su mismo archivo Compose:

```bash
docker compose down
```

o:

```bash
docker compose -f docker-compose.debian.yml down
```

## Publicar una nueva imagen PHP

Este procedimiento se utiliza cuando cambian los Dockerfiles, `php/extensions.txt`, PHP, Composer, ODBC u otra dependencia incluida en la imagen. Los cambios normales del código de las aplicaciones no necesitan reconstruirla porque el código se monta desde el host.

### 1. Preparar el candidato de staging

Asigna un tag nuevo únicamente a staging en `.env`:

```dotenv
PHP_IMAGE_PRODUCTION_TAG=1.0.0
PHP_IMAGE_STAGING_TAG=1.1.0-rc1
```

Construye e inicia sólo la pareja de staging:

```bash
docker compose build --pull php-staging
docker compose up -d php-staging nginx-staging
```

Producción continúa utilizando `dkr-php-alpine:1.0.0`. Con el Compose Debian, los mismos tags se aplican al repositorio local `dkr-php-debian`.

### 2. Validar staging

Realiza las comprobaciones en:

```text
http://localhost:8081/lskdev/
```

Puedes consultar las imágenes asociadas a los servicios con:

```bash
docker compose images
```

### 3. Promover la imagen aprobada

Después de la aprobación, asigna a producción exactamente el tag probado:

```dotenv
PHP_IMAGE_PRODUCTION_TAG=1.1.0-rc1
PHP_IMAGE_STAGING_TAG=1.1.0-rc1
```

Recrea únicamente la pareja de producción sin reconstruir la imagen:

```bash
docker compose up -d --pull never --no-build php-production nginx-production
```

`--pull never --no-build`, junto con `pull_policy: never` en los servicios PHP, garantiza que producción utilice la imagen local que ya fue validada en staging. Si esa imagen no existe en el host, el comando falla en lugar de construirla o intentar descargar otra con el mismo nombre.

### 4. Preparar la siguiente versión

Mantén producción en el tag aprobado y cambia solamente staging:

```dotenv
PHP_IMAGE_PRODUCTION_TAG=1.1.0-rc1
PHP_IMAGE_STAGING_TAG=1.2.0-rc1
```

### Rollback

Conserva el tag anterior en el host. Para volver atrás, restaura su valor y recrea producción sin build:

```dotenv
PHP_IMAGE_PRODUCTION_TAG=1.0.0
```

```bash
docker compose up -d --pull never --no-build php-production nginx-production
```

Si utilizas Debian, agrega `-f docker-compose.debian.yml` a todos los comandos del procedimiento.

## Acceso

Desde el mismo servidor:

- Página principal: `http://localhost:8080/`
- Producción: `http://localhost:8080/lskprd/`
- Staging: `http://localhost:8081/lskdev/`

Desde otra computadora de la red local, reemplaza `localhost` por la IP o nombre del servidor, por ejemplo:

```text
http://192.168.1.50:8080/lskprd/
http://192.168.1.50:8081/lskdev/
```

El firewall del host debe permitir los puertos necesarios. En una instalación real conviene permitir 8081 sólo desde los equipos autorizados para validar staging.

## Uploads

Las aplicaciones escriben los archivos en:

```text
storage/app/uploads/
```

Nginx los publica como contenido estático en:

- Producción: `http://IP_O_HOST:8080/lskprd/uploads/<archivo>`
- Staging: `http://IP_O_HOST:8081/lskdev/uploads/<archivo>`

Ambos Nginx permiten un cuerpo HTTP máximo de `20m` mediante `client_max_body_size`. El límite incluye el archivo y los demás campos del formulario; una petición mayor recibe `413 Request Entity Too Large` antes de llegar a PHP. La aplicación y PHP pueden aplicar límites iguales o menores, pero no deberían aceptar un tamaño mayor que Nginx.

Nginx monta el código como solo lectura, desactiva el listado de directorios y bloquea archivos ocultos y extensiones PHP dentro de uploads. PHP conserva acceso de escritura porque es quien recibe y guarda el archivo.

La aplicación sigue siendo responsable de:

- limitar tamaño y cantidad de archivos;
- validar contenido, MIME y extensión;
- generar nombres seguros y evitar colisiones;
- impedir rutas relativas como `../`;
- aplicar autorización antes de guardar o entregar información privada.

Esta ruta de Nginx es apropiada para archivos públicos. Los documentos privados no deberían publicarse directamente desde `uploads`; deben entregarse mediante una ruta autenticada de la aplicación o un mecanismo equivalente.

## Operación y comprobaciones

Consultar el estado:

```bash
docker compose ps
```

Consultar logs:

```bash
docker compose logs -f nginx-production php-production nginx-staging php-staging
```

Los cuatro servicios usan el driver `json-file` con rotación explícita: cada contenedor conserva como máximo 3 segmentos de 10 MB, aproximadamente 30 MB por servicio y 120 MB para el stack completo. Cuando se alcanza el límite, Docker elimina el segmento más antiguo.

La rotación limita el uso de disco y no reserva 120 MB por adelantado. Los archivos son administrados internamente por Docker: consúltalos mediante `docker compose logs` y no los edites directamente en el directorio de datos del motor.

Después de modificar esta política, recrea los servicios para que los nuevos contenedores la reciban:

```bash
docker compose up -d --force-recreate
```

Comprobar Nginx:

```text
http://localhost:8080/health
http://localhost:8081/health
```

Ambas direcciones deben responder `200 OK` con `ok`. Cada Nginx y su PHP tienen healthchecks independientes. Las comprobaciones son deliberadamente livianas: verifican que cada Nginx responda y que el proceso principal de cada PHP-FPM continúe vivo; no prueban la base de datos ni toda la aplicación.

Entrar a un contenedor PHP:

```bash
docker compose exec php-staging bash
docker compose exec php-production bash
```

Ejecutar Composer en cada entorno:

```bash
docker compose exec php-staging composer install --working-dir=/var/www/lskdev
docker compose exec php-production composer install --working-dir=/var/www/lskprd --no-dev --optimize-autoloader
```

Si utilizas Debian, agrega `-f docker-compose.debian.yml` después de `docker compose`, como se indicó al elegir la variante.

Los cambios en los archivos montados desde el host se reflejan sin reconstruir la imagen. Cuando cambie el runtime PHP, sigue el procedimiento de staging y promoción; evita `docker compose up -d --build` sin indicar servicios porque construiría también producción.

```bash
docker compose build --pull php-staging
docker compose up -d php-staging nginx-staging
```

## Detención y actualización

Detener sin eliminar los contenedores:

```bash
docker compose stop
```

Detener y eliminar contenedores y redes del proyecto:

```bash
docker compose down
```

Actualizar únicamente los Nginx:

```bash
docker compose pull nginx-production nginx-staging
docker compose up -d nginx-production nginx-staging
```

`docker compose down` no elimina las aplicaciones porque son carpetas del host montadas mediante bind mounts. Este proyecto no define volúmenes Docker con datos persistentes.

## Problemas frecuentes

### El puerto ya está ocupado

Si Compose informa que 8080 o 8081 ya está en uso, detén el proceso o stack que lo ocupa. También puedes cambiar el lado izquierdo del mapeo en ambos archivos Compose, por ejemplo `9081:80`; en ese caso actualiza las URLs configuradas en la aplicación.

### Nginx devuelve 404

Comprueba que:

- la variable `.env` apunta a la raíz correcta;
- existe `public/index.php`;
- estás usando `/lskprd/` en 8080 o `/lskdev/` en 8081;
- la aplicación conserva su prefijo al generar URLs.

### Nginx devuelve 502

Revisa `docker compose ps` y los logs de `php-production` o `php-staging`. Un 502 normalmente indica que Nginx no pudo conectarse al PHP-FPM correspondiente.

### Uploads, caché o logs fallan

Comprueba que la carpeta exista y que PHP-FPM tenga permisos de escritura sobre el bind mount. Nginx no necesita permisos de escritura.

### La aplicación no conecta con SQL Server

Verifica host, puerto, usuario, contraseña, cifrado y certificados en la configuración de la aplicación. Desde el contenedor puedes usar `sqlcmd` para hacer una prueba independiente.

## Seguridad pendiente

La configuración actual usa HTTP y staging queda accesible para cualquier equipo que pueda alcanzar el puerto 8081. Antes de una instalación sensible, evalúa firewall, autenticación para staging y TLS mediante un proxy inverso o una ampliación de Nginx.

Los ajustes de PHP-FPM para poca memoria, límites de `php.ini`, montaje de código PHP como solo lectura y fijación de imágenes por digest están documentados en [RECOMENDACIONES.md](RECOMENDACIONES.md).
