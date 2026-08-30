# Permisos de archivos y directorios

Esta guía explica cómo preparar en el host las carpetas configuradas mediante
`PHP_APP_PATH_HME`, `PHP_APP_PATH_PRD` y `PHP_APP_PATH_DEV`.

El objetivo es que:

- el administrador pueda descargar y actualizar el código con Git;
- el usuario de SFTP/FTP pueda crear y editar archivos;
- Nginx pueda leer los archivos públicos, pero no modificarlos;
- PHP pueda leer la aplicación y escribir solamente en uploads, caché, logs u
  otros directorios que realmente lo necesiten;
- no sea necesario utilizar permisos inseguros como `777`.

## Conceptos básicos

En Linux, cada archivo tiene:

- un **propietario**: normalmente el usuario que lo creó;
- un **grupo**: permite compartir acceso entre varios usuarios;
- permisos para el propietario, el grupo y los demás usuarios.

Los permisos más habituales son:

| Permiso | Archivos | Directorios |
| --- | --- | --- |
| `r` (read) | Leer el contenido | Ver los nombres del directorio |
| `w` (write) | Modificar el archivo | Crear, borrar o renombrar elementos |
| `x` (execute) | Ejecutar el archivo | Entrar y recorrer el directorio |

Por eso un directorio necesita `x` además de `r` para que Nginx o PHP puedan
acceder a los archivos que contiene.

Los valores numéricos usados en esta guía significan:

| Valor | Resultado |
| --- | --- |
| `664` | Propietario y grupo leen/escriben; los demás sólo leen |
| `775` | Propietario y grupo tienen acceso completo; los demás leen y recorren |
| `2775` | Igual que `775`, pero los elementos nuevos heredan el grupo del directorio |

No uses `chmod -R 777`: cualquier usuario o proceso del equipo podría modificar
el código.

## Qué usuario crea cada archivo

Los bind mounts no copian los archivos al contenedor. Los contenedores ven los
mismos archivos que existen en el host.

- `git clone` ejecutado como usuario normal crea archivos de ese usuario.
- `sudo git clone`, `sudo touch` o `sudo cp` crea archivos de `root`.
- SFTP/FTP crea archivos del usuario utilizado para iniciar sesión.
- PHP crea archivos con el UID/GID de su proceso PHP-FPM.
- Nginx sólo necesita lectura porque sus montajes terminan en `:ro`.

Si Git y SFTP usan usuarios diferentes, conviene que ambos pertenezcan a un
grupo común. Si se crea accidentalmente un archivo con `sudo`, puede seguir
siendo legible, pero los usuarios normales probablemente no podrán editarlo.

## Configuración recomendada en Linux

Los siguientes ejemplos utilizan estos nombres. Sustitúyelos por los reales:

```text
Administrador: operador
Usuario SFTP/FTP: transferencia
Grupo compartido: linsock-editors
Raíz de los proyectos: /srv/linsock
```

Ejecuta primero los comandos de inspección y confirma las rutas antes de usar
un comando con `-R`, porque éste afecta todo el contenido descendiente.

### 1. Crear un grupo común

```bash
sudo groupadd linsock-editors
```

- `sudo`: ejecuta una tarea administrativa.
- `groupadd`: crea un grupo local.
- `linsock-editors`: nombre elegido para el grupo de editores.

Si el grupo ya existe, `groupadd` informará el error correspondiente y no es
necesario volver a crearlo. Puedes comprobarlo con:

```bash
getent group linsock-editors
```

- `getent group`: consulta la base de grupos del sistema.
- `linsock-editors`: limita el resultado al grupo solicitado.

### 2. Agregar los usuarios al grupo

```bash
sudo usermod -aG linsock-editors operador
sudo usermod -aG linsock-editors transferencia
```

- `usermod`: modifica un usuario existente.
- `-G linsock-editors`: indica el grupo suplementario que se agregará.
- `-a`: agrega el grupo sin eliminar los demás grupos del usuario. No omitas
  esta opción.
- el último argumento es el usuario que se modifica.

El usuario debe cerrar y volver a iniciar sesión para recibir el grupo nuevo.
Para comprobarlo:

```bash
id operador
id transferencia
```

`id` muestra el UID, el GID principal y todos los grupos de un usuario.

### 3. Asignar propietario y grupo

Suponiendo que las tres rutas ya existen:

```bash
sudo chown -R operador:linsock-editors /srv/linsock/homepage
sudo chown -R operador:linsock-editors /srv/linsock/lskprd
sudo chown -R operador:linsock-editors /srv/linsock/lskdev
```

- `chown`: cambia propietario y grupo.
- `-R`: aplica el cambio recursivamente a todo el contenido.
- `operador:linsock-editors`: establece el propietario antes de `:` y el grupo
  después de `:`.
- el último argumento es la ruta exacta que se modificará.

No reemplaces estas rutas por `/`, `/srv` ni otro directorio general.

### 4. Aplicar permisos base

```bash
sudo find /srv/linsock/homepage /srv/linsock/lskprd /srv/linsock/lskdev -type d -exec chmod 2775 {} +
sudo find /srv/linsock/homepage /srv/linsock/lskprd /srv/linsock/lskdev -type f -exec chmod 0664 {} +
```

Primer comando:

- `find`: busca elementos dentro de las rutas indicadas.
- `-type d`: selecciona únicamente directorios.
- `-exec chmod 2775 {} +`: aplica `2775` a los directorios encontrados; `{}`
  representa los resultados y `+` los agrupa en pocas ejecuciones.

Segundo comando:

- `-type f`: selecciona únicamente archivos normales.
- `chmod 0664`: da lectura/escritura al propietario y al grupo, y sólo lectura
  a los demás.

El bit inicial `2` de `2775` activa **setgid** en cada directorio. No ejecuta el
directorio como otro usuario: hace que los archivos nuevos hereden el grupo
`linsock-editors` en vez del grupo principal de quien los crea.

Estos permisos pueden quitar el permiso de ejecución de scripts Bash existentes.
Si realmente necesitas ejecutar uno, concédelo sólo a ese archivo:

```bash
chmod 0775 /srv/linsock/lskdev/ruta/script.sh
```

`chmod 0775` agrega ejecución para propietario, grupo y otros sin modificar
recursivamente el resto del proyecto.

### 5. Usar una umask colaborativa

Para una sesión de terminal desde la que se usarán Git o herramientas de
despliegue:

```bash
umask 0002
```

`umask` define qué permisos se quitan al crear elementos nuevos. El valor
`0002` suele producir archivos `664` y directorios `775`, permitiendo que el
grupo compartido continúe editándolos.

La umask debe configurarse también en el servicio SFTP/FTP según el servidor
utilizado. El nombre exacto de la opción cambia entre OpenSSH, vsftpd, ProFTPD y
otros programas; confirma su documentación y reinicia sólo ese servicio después
del cambio.

Se recomienda **SFTP sobre SSH** en lugar de FTP tradicional, porque cifra tanto
la contraseña como los archivos transferidos.

## Permisos especiales para PHP

El código general necesita lectura, pero sólo algunos directorios deben aceptar
escritura desde PHP. Ejemplos habituales:

```text
storage/app/uploads
storage/logs
storage/framework/cache
storage/framework/sessions
bootstrap/cache
```

La lista exacta depende de la aplicación y del framework. No concedas escritura
a todo el proyecto solamente porque una de estas carpetas la necesita.

### 1. Averiguar el UID/GID de PHP-FPM

Para Debian:

```bash
docker compose -f docker-compose.debian.yml run --rm --no-deps php-production id www-data
docker compose -f docker-compose.debian.yml run --rm --no-deps php-staging id www-data
```

Para Alpine:

```bash
docker compose run --rm --no-deps php-production id www-data
docker compose run --rm --no-deps php-staging id www-data
```

- `docker compose`: administra los servicios definidos en Compose.
- `-f docker-compose.debian.yml`: selecciona la variante Debian; al omitirlo se
  utiliza `docker-compose.yml` (Alpine).
- `run`: crea un contenedor temporal para ejecutar un comando.
- `--rm`: elimina ese contenedor temporal al finalizar.
- `--no-deps`: no inicia Nginx ni otros servicios relacionados.
- `php-production`: servicio cuya imagen se inspecciona.
- `id www-data`: muestra el UID y GID del usuario de PHP-FPM.

En la imagen Debian actual, `www-data` devuelve UID/GID `33:33`. No copies ese
valor automáticamente a Alpine ni a una imagen futura: compruébalo con el
comando anterior.

### 2. Conceder escritura mediante ACL

Las ACL permiten dar acceso al UID de PHP sin convertirlo en propietario de
todo el código. En Debian/Ubuntu, instala la herramienta si falta:

```bash
sudo apt-get update
sudo apt-get install acl
```

- `apt-get update`: actualiza el índice local de paquetes.
- `apt-get install acl`: instala `setfacl` y `getfacl`.

Ejemplo para producción Debian, donde PHP usa UID `33`:

```bash
sudo find /srv/linsock/lskprd/storage -type d -exec setfacl -m u:33:rwx,g:linsock-editors:rwx,m::rwx {} +
sudo find /srv/linsock/lskprd/storage -type f -exec setfacl -m u:33:rw-,g:linsock-editors:rw-,m::rw- {} +
sudo find /srv/linsock/lskprd/storage -type d -exec setfacl -d -m u:33:rwx,g:linsock-editors:rwx,m::rwx {} +
```

- `setfacl`: modifica la lista de permisos ACL.
- `-m`: agrega o modifica entradas.
- `u:33:rwx`: concede lectura, escritura y recorrido al UID 33 en directorios.
- `u:33:rw-`: concede lectura y escritura, pero no ejecución, en archivos.
- `g:linsock-editors`: mantiene el acceso del grupo de editores.
- `m::rwx` o `m::rw-`: establece la máscara máxima efectiva de las entradas.
- `-d`: crea una ACL predeterminada que heredarán los elementos futuros.

Se separan archivos y directorios porque PHP necesita `x` para recorrer un
directorio, pero un archivo subido normal no debe quedar marcado como
ejecutable. El tercer comando aplica la ACL predeterminada a todos los
directorios existentes para que también funcione en subcarpetas futuras.

Repite la operación sólo sobre cada directorio escribible real. Por ejemplo,
si la aplicación únicamente sube archivos, usa como destino exacto
`/srv/linsock/lskprd/storage/app/uploads` en lugar de todo `storage`.

Para staging, sustituye la ruta por `/srv/linsock/lskdev/...` y utiliza el UID
obtenido al inspeccionar `php-staging`.

Comprueba el resultado con:

```bash
getfacl /srv/linsock/lskprd/storage/app/uploads
```

`getfacl` muestra los permisos tradicionales y todas las entradas ACL del
directorio indicado.

### 3. Proteger archivos con secretos

El permiso base `664` facilita la lectura desde los contenedores, pero también
permite que otros usuarios locales del host lean el archivo. Para archivos con
contraseñas o tokens, como el `.env` propio de una aplicación, elimina el acceso
de “otros” y concede lectura explícita a PHP:

```bash
chmod 0660 /srv/linsock/lskprd/.env
sudo setfacl -m u:33:r-- /srv/linsock/lskprd/.env
```

- `chmod 0660`: permite lectura/escritura al propietario y al grupo, y ningún
  acceso al resto de usuarios.
- `u:33:r--`: permite al UID 33 leer el secreto sin poder modificarlo.

Nginx no necesita leer este archivo. Repite la protección para otros archivos
sensibles y utiliza en cada entorno el UID de PHP que hayas comprobado.

## Nginx y la página principal

En este proyecto Nginx monta las aplicaciones y la página principal con `:ro`.
Aunque el host concediera escritura, el contenedor Nginx seguiría viendo esos
montajes como sólo lectura.

Para conocer su UID puedes ejecutar:

```bash
docker compose -f docker-compose.debian.yml run --rm --no-deps nginx-production id nginx
```

La imagen actual devuelve UID/GID `101:101`. Normalmente no es necesario crear
una ACL para ese UID: los permisos base `664` en archivos y `2775` en
directorios ya permiten la lectura. Dar a Nginx escritura no aporta ninguna
ventaja para esta arquitectura.

## Git, SFTP/FTP y Composer

### Git

Clona siempre como usuario normal, nunca con `sudo`:

```bash
umask 0002
git clone URL_DEL_REPOSITORIO /srv/linsock/lskdev
```

- `git clone`: descarga una copia de trabajo del repositorio.
- `URL_DEL_REPOSITORIO`: dirección real del repositorio.
- el último argumento es la carpeta de destino.

Si la carpeta fue clonada antes de crear el grupo compartido, aplica los pasos
de propietario, grupo y permisos base descritos anteriormente.

### SFTP/FTP

El usuario de transferencia debe pertenecer a `linsock-editors`, usar una umask
`0002` y tener acceso solamente a las rutas que necesita. No le concedas acceso
administrativo ni permiso para cambiar producción si su función se limita a
staging.

Permitir que un usuario transfiera o edite archivos `.php` equivale a permitirle
cambiar el código que ejecutará el servidor. Usa cuentas individuales, claves
SSH cuando sea posible y registros de acceso.

### Composer dentro del contenedor

Un comando ejecutado como `root` dentro del contenedor puede crear en el bind
mount archivos pertenecientes a `root` en el host. Comprueba después de ejecutar
Composer quién es el propietario de `vendor` y `composer.lock`.

Para inspeccionarlos:

```bash
ls -ld /srv/linsock/lskdev/vendor
ls -l /srv/linsock/lskdev/composer.lock
```

- `ls -l`: muestra permisos, propietario, grupo y tamaño.
- `-d`: muestra el propio directorio en lugar de listar su contenido.

Si quedaron como `root`, corrige únicamente esos destinos conocidos:

```bash
sudo chown -R operador:linsock-editors /srv/linsock/lskdev/vendor
sudo chown operador:linsock-editors /srv/linsock/lskdev/composer.lock
```

## Archivos creados accidentalmente con sudo

Localiza archivos pertenecientes a `root` dentro de una aplicación:

```bash
find /srv/linsock/lskdev -user root -ls
```

- `-user root`: selecciona elementos cuyo propietario es `root`.
- `-ls`: muestra cada resultado con permisos y propietario.

Después de revisar la lista, corrige un archivo concreto:

```bash
sudo chown operador:linsock-editors /srv/linsock/lskdev/ruta/archivo.php
chmod 0664 /srv/linsock/lskdev/ruta/archivo.php
```

Para corregir un directorio concreto y su contenido:

```bash
sudo chown -R operador:linsock-editors /srv/linsock/lskdev/ruta/directorio
```

Evita ejecutar un `chown -R` general hasta confirmar exactamente qué ruta y qué
archivos se modificarán.

## Comandos de diagnóstico útiles

Ver permisos de cada componente de una ruta:

```bash
namei -l /srv/linsock/lskprd/public/index.php
```

`namei -l` separa la ruta y muestra el propietario y los permisos de cada
directorio. Es útil cuando el archivo tiene permiso de lectura, pero un
directorio superior impide llegar hasta él.

Ver archivos y directorios de una carpeta:

```bash
ls -la /srv/linsock/lskprd
```

- `-l`: formato detallado.
- `-a`: incluye nombres ocultos como `.env` y `.git`.

Probar escritura de PHP en producción:

```bash
docker compose -f docker-compose.debian.yml exec --user www-data php-production touch /var/www/lskprd/storage/app/uploads/prueba-permisos.txt
```

- `exec`: ejecuta el comando dentro del contenedor que ya está iniciado.
- `--user www-data`: usa el mismo usuario no privilegiado de PHP-FPM.
- `touch`: crea un archivo vacío o actualiza su fecha si ya existe.

Si funciona, elimina el archivo de prueba desde el host:

```bash
rm /srv/linsock/lskprd/storage/app/uploads/prueba-permisos.txt
```

`rm` elimina únicamente el archivo exacto indicado. Comprueba la ruta antes de
ejecutarlo.

Probar que Nginx sólo tiene lectura:

```bash
docker compose -f docker-compose.debian.yml exec nginx-production touch /var/www/lskprd/public/prueba.txt
```

El resultado esperado es un error de sistema de archivos de sólo lectura. No se
debe crear el archivo.

## Consideraciones para Windows

Cuando Docker Desktop monta una ruta como `C:/linsock/...`, los permisos finales
dependen de Windows, Docker Desktop y, si corresponde, WSL2. `chown`, `chmod` y
las ACL de Linux pueden no conservarse o comportarse como en un sistema Linux
nativo.

- Configura el acceso de los usuarios desde **Propiedades > Seguridad** de la
  carpeta en Windows.
- No uses `setfacl` sobre `/mnt/c/...` suponiendo que se comportará igual que un
  sistema de archivos Linux.
- Si necesitas permisos Linux exactos, guarda el proyecto dentro del sistema de
  archivos de WSL2, por ejemplo `/srv/linsock`, y ejecuta Compose desde WSL2.
- Mantén Docker Desktop configurado para compartir únicamente las carpetas
  necesarias.

En Windows sigue siendo válida la regla principal: Nginx sólo lee, PHP escribe
únicamente en las carpetas operativas y los usuarios humanos editan mediante
permisos del host.

## Resumen de la configuración recomendada

| Elemento | Recomendación |
| --- | --- |
| Propietario del código | Usuario humano o de despliegue, nunca `root` |
| Grupo del código | Grupo común de administradores y usuarios SFTP |
| Directorios normales | `2775` |
| Archivos normales | `664` |
| Archivos ejecutables | `775`, sólo cuando realmente deban ejecutarse |
| Umask de Git/SFTP | `0002` |
| PHP-FPM | Lectura general y ACL de escritura sólo en uploads/caché/logs |
| Nginx | Lectura mediante permisos base y bind mounts `:ro` |
| Transferencias | SFTP/SSH preferido frente a FTP sin cifrar |
| Permiso que debe evitarse | `777` |
