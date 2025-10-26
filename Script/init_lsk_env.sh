#!/bin/bash
# ========================================================
# Script: init_lsk_env.sh
# Autor: Gustavo Russo
# Descripción: Inicializa estructura para proyectos Docker + LSK
# ========================================================

# --- Configuración de usuarios y permisos ---
USER_DOCKER="docker"
USER_WEB="www-data"

# --- Directorios base ---
DIR_DOCKER="/opt/docker"
DIR_APPS="/var/lsk"

# --- Colores para salida ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo -e "${YELLOW}📦 Creando estructura de Docker en $DIR_DOCKER...${RESET}"

# Estructura de contenedores Docker
mkdir -p $DIR_DOCKER/{dkr-php-sqlserver,dkr-node-service,dkr-portainer,dkr-ftp}
touch $DIR_DOCKER/README.md

# Ejemplo de estructura PHP + SQLServer
mkdir -p $DIR_DOCKER/dkr-php-sqlserver/{php,sqlserver,data,logs}
cat <<'EOF' > $DIR_DOCKER/dkr-php-sqlserver/README.md
# Docker Stack: PHP + SQL Server
Contiene los servicios y configuraciones del entorno PHP con SQL Server.
EOF

# --- Node service ejemplo ---
mkdir -p $DIR_DOCKER/dkr-node-service/{src,logs}
echo "# Docker Stack: Node.js Service" > $DIR_DOCKER/dkr-node-service/README.md

# --- Portainer ---
mkdir -p $DIR_DOCKER/dkr-portainer/data
echo "# Docker Stack: Portainer" > $DIR_DOCKER/dkr-portainer/README.md

# --- FTP ---
mkdir -p $DIR_DOCKER/dkr-ftp/{data,conf}
echo "# Docker Stack: FTP Service" > $DIR_DOCKER/dkr-ftp/README.md

# --- Asignar permisos ---
chown -R $USER_DOCKER:$USER_DOCKER $DIR_DOCKER
chmod -R 775 $DIR_DOCKER

echo -e "${GREEN}✅ Estructura Docker creada correctamente.${RESET}"

# ========================================================
echo -e "${YELLOW}🌐 Creando estructura de aplicaciones en $DIR_APPS...${RESET}"

# Estructura de proyectos de aplicaciones
mkdir -p $DIR_APPS/{hcb,gardenlife,linsock,testdev}
touch $DIR_APPS/README.md

for app in hcb gardenlife linsock testdev; do
    mkdir -p $DIR_APPS/$app/{public,src,logs,storage}
    cat <<EOF > $DIR_APPS/$app/README.md
# Proyecto $app
Aplicación PHP o Node del entorno LSK.
EOF
    touch $DIR_APPS/$app/.env.example
done

# Asignar permisos
chown -R $USER_WEB:$USER_WEB $DIR_APPS
chmod -R 775 $DIR_APPS

echo -e "${GREEN}✅ Estructura /var/lsk creada correctamente.${RESET}"

# ========================================================
echo -e "${YELLOW}🧹 Limpieza y resumen...${RESET}"
tree -L 2 $DIR_DOCKER $DIR_APPS 2>/dev/null || ls -R $DIR_DOCKER $DIR_APPS

echo -e "${GREEN}✨ Entorno LSK inicializado exitosamente.${RESET}"
