# Imagen base de PHP 8.4 con FPM en Alpine
FROM php:8.4-fpm-alpine3.24

ARG TARGETARCH

RUN if [ "$TARGETARCH" != "amd64" ]; then \
        echo "ERROR: esta imagen sólo soporta linux/amd64"; \
        exit 1; \
    fi

# Aceptar EULA de Microsoft
ENV ACCEPT_EULA=Y \
    PATH="${PATH}:/opt/mssql-tools18/bin"

# Bash se conserva para los scripts de las aplicaciones.
RUN apk add --no-cache bash

# Descargar e instalar ODBC y herramientas de SQL Server
RUN apk add --no-cache --virtual .odbc-verification-deps gnupg \
    && export GNUPGHOME="$(mktemp -d)" \
    && curl -fSLO https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.apk \
    && curl -fSLO https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.apk \
    && curl -fSLO https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.sig \
    && curl -fSLO https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.sig \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --import - \
    && gpg --verify msodbcsql18_18.4.1.1-1_amd64.sig msodbcsql18_18.4.1.1-1_amd64.apk \
    && gpg --verify mssql-tools18_18.4.1.1-1_amd64.sig mssql-tools18_18.4.1.1-1_amd64.apk \
    && apk add --no-cache --allow-untrusted msodbcsql18_18.4.1.1-1_amd64.apk mssql-tools18_18.4.1.1-1_amd64.apk \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apk del .odbc-verification-deps \
    && rm -f msodbcsql18_18.4.1.1-1_amd64.apk mssql-tools18_18.4.1.1-1_amd64.apk \
        msodbcsql18_18.4.1.1-1_amd64.sig mssql-tools18_18.4.1.1-1_amd64.sig

# Copiar el instalador de extensiones PHP desde la imagen oficial
COPY --from=ghcr.io/mlocati/php-extension-installer:2.11.12 /usr/bin/install-php-extensions /usr/bin/install-php-extensions

# Composer se conserva para administrar dependencias bajo demanda.
COPY --from=composer:2.10.2 /usr/bin/composer /usr/local/bin/composer

# Lista común de extensiones para las variantes Alpine y Debian.
COPY extensions.txt /tmp/php-extensions.txt

# Asignar permisos y ejecutar la instalación de extensiones
RUN chmod +x /usr/bin/install-php-extensions \
    && sync \
    && set -- $(cat /tmp/php-extensions.txt) \
    && install-php-extensions "$@" \
    && rm -f /tmp/php-extensions.txt

# Definir el directorio de trabajo
WORKDIR /var/www
