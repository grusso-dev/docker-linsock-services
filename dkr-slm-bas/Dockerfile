# Etapa 1: instalar dependencias con Composer
FROM composer:2 AS vendor

WORKDIR /app
COPY composer.json ./
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader
COPY . .

# Etapa 2: Imagen final con PHP + Apache + SQL Server drivers
FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    unzip zip curl git gnupg2 \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

COPY apache.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

COPY --from=vendor /app/public ./public
COPY --from=vendor /app/src ./src
COPY --from=vendor /app/vendor ./vendor
COPY --from=vendor /app/composer.json ./composer.json

# Soporte SQL Server
RUN set -eux; \
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor \
      | tee /usr/share/keyrings/microsoft.gpg > /dev/null; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
      > /etc/apt/sources.list.d/mssql-release.list; \
    apt-get update; \
    ACCEPT_EULA=Y apt-get install -y \
      msodbcsql18 \
      mssql-tools18 \
      unixodbc-dev \
      libgssapi-krb5-2; \
    pecl install sqlsrv pdo_sqlsrv; \
    docker-php-ext-enable sqlsrv pdo_sqlsrv; \
    rm -rf /var/lib/apt/lists/*

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copiar Composer al contenedor final (útil en desarrollo)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer


EXPOSE 80
CMD ["apache2-foreground"]
