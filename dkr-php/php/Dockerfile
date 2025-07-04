# Imagen base de PHP 8.3 con FPM en Alpine
FROM php:8.3-fpm-alpine

# Aceptar EULA de Microsoft
ENV ACCEPT_EULA=Y

# Instalar herramientas básicas y dependencias de PHP
RUN apk add --update --no-cache \
    bash \
    gnupg \
    less \
    libpng-dev \
    libzip-dev \
    su-exec \
    unzip \
    && rm -rf /var/cache/apk/*

# Descargar e instalar ODBC y herramientas de SQL Server
RUN curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.sig \
    && curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.sig \
    && curl https://packages.microsoft.com/keys/microsoft.asc | gpg --import - \
    && gpg --verify msodbcsql18_18.4.1.1-1_amd64.sig msodbcsql18_18.4.1.1-1_amd64.apk \
    && gpg --verify mssql-tools18_18.4.1.1-1_amd64.sig mssql-tools18_18.4.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql18_18.4.1.1-1_amd64.apk mssql-tools18_18.4.1.1-1_amd64.apk \
    && rm *.apk *.sig

# Copiar el instalador de extensiones PHP desde la imagen oficial
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/install-php-extensions

# Asignar permisos y ejecutar la instalación de extensiones
RUN chmod +x /usr/bin/install-php-extensions \
    && sync \
    && install-php-extensions \
        bcmath \
        ds \
        exif \
        gd \
        intl \
        opcache \
        pcntl \
        pdo_sqlsrv \
        redis \
        sqlsrv \
        zip

# Definir el directorio de trabajo
WORKDIR /var/www