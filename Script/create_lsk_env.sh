#!/bin/bash
# ========================================================
# Script: create_lsk_env.sh
# Autor: Gustavo Russo
# Descripción: Crea entornos Docker o LSK con menú interactivo
# ========================================================

# --- Configuración de usuarios ---
USER_DOCKER="docker"
USER_WEB="www-data"

# --- Directorios base ---
DIR_DOCKER="/opt/docker"
DIR_APPS="/var/lsk"

# --- Colores ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# ========================================================
# Función: Crear entorno Docker
# ========================================================
create_docker_env() {
    echo -e "${YELLOW}📦 Creando entorno Docker...${RESET}"
    read -p "👉 Ingresá el nombre del stack (por ejemplo: dkr-php-sqlserver): " STACK_NAME
    if [ -z "$STACK_NAME" ]; then
        echo -e "${RED}❌ No ingresaste un nombre válido.${RESET}"
        return
    fi

    STACK_DIR="$DIR_DOCKER/$STACK_NAME"
    if [ -d "$STACK_DIR" ]; then
        echo -e "${RED}⚠️  Ya existe un entorno con ese nombre.${RESET}"
        return
    fi

    mkdir -p "$STACK_DIR"/{php,sqlserver,data,logs}

    cat <<EOF > "$STACK_DIR/README.md"
# Docker Stack: $STACK_NAME
Entorno Docker creado automáticamente.
EOF

    touch "$STACK_DIR/docker-compose.yml"
    chown -R $USER_DOCKER:$USER_DOCKER "$STACK_DIR"
    chmod -R 775 "$STACK_DIR"

    echo -e "${GREEN}✅ Entorno Docker creado en $STACK_DIR${RESET}"
}

# ========================================================
# Función: Crear entorno de proyectos LSK
# ========================================================
create_lsk_projects() {
    echo -e "${YELLOW}🌐 Creando entorno de proyectos LSK...${RESET}"
    mkdir -p "$DIR_APPS"

    read -p "👉 Ingresá nombres de proyectos separados por espacio (ej: hcb gardenlife linsock): " PROJECTS

    for app in $PROJECTS; do
        APP_DIR="$DIR_APPS/$app"
        if [ -d "$APP_DIR" ]; then
            echo -e "${RED}⚠️  El proyecto '$app' ya existe, se omite.${RESET}"
            continue
        fi

        mkdir -p "$APP_DIR"/{public,src,logs,storage}

        # Crear README
        cat <<EOF > "$APP_DIR/README.md"
# Proyecto $app
Aplicación PHP o Node del entorno LSK.
EOF

        # Preguntar si quiere crear el archivo .env
        read -p "¿Querés crear el archivo .env base para $app? (s/n): " CREATE_ENV
        if [[ "$CREATE_ENV" =~ ^[sS]$ ]]; then
            cat <<EOF > "$APP_DIR/.env"
# ===============================================
# Archivo .env - Entorno $app
# ===============================================
APP_NAME="$app"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost

# --- Base de datos SQL Server ---
DB_CONNECTION=sqlsrv
DB_HOST=sqlserver
DB_PORT=1433
DB_DATABASE=Garden_Life_SA_30
DB_USERNAME=sa
DB_PASSWORD=YourStrong!Passw0rd

# --- Configuración PHP ---
TIMEZONE=America/Argentina/Buenos_Aires
LOCALE=es_AR

# --- Otros servicios ---
REDIS_HOST=redis
REDIS_PORT=6379

# --- API Keys (modificar según corresponda) ---
API_KEY_DEV=123456789
EOF
            echo -e "${GREEN}✅ Archivo .env creado para $app${RESET}"
        fi
    done

    chown -R $USER_WEB:$USER_WEB "$DIR_APPS"
    chmod -R 775 "$DIR_APPS"

    echo -e "${GREEN}✅ Proyectos creados en $DIR_APPS${RESET}"
}

# ========================================================
# Función: Listar entornos existentes
# ========================================================
list_environments() {
    echo -e "${YELLOW}📂 Listando entornos existentes...${RESET}"

    echo ""
    echo -e "${GREEN}🧱 Directorios Docker (${DIR_DOCKER}):${RESET}"
    if [ -d "$DIR_DOCKER" ]; then
        ls -1 "$DIR_DOCKER"
    else
        echo -e "${RED}(no existe el directorio)${RESET}"
    fi

    echo ""
    echo -e "${GREEN}🌐 Proyectos LSK (${DIR_APPS}):${RESET}"
    if [ -d "$DIR_APPS" ]; then
        ls -1 "$DIR_APPS"
    else
        echo -e "${RED}(no existe el directorio)${RESET}"
    fi
}

# ========================================================
# Menú principal
# ========================================================
while true; do
    clear
    echo -e "${YELLOW}==============================================${RESET}"
    echo -e "${YELLOW}   🚀 Script de Creación de Entornos LSK/Docker${RESET}"
    echo -e "${YELLOW}==============================================${RESET}"
    echo ""
    echo "1) Crear entorno Docker"
    echo "2) Crear entorno de proyectos LSK"
    echo "3) Crear ambos"
    echo "4) Listar entornos existentes"
    echo "5) Salir"
    echo ""
    read -p "👉 Elegí una opción [1-5]: " OPTION
    echo ""

    case $OPTION in
        1)
            create_docker_env
            ;;
        2)
            create_lsk_projects
            ;;
        3)
            create_docker_env
            echo ""
            create_lsk_projects
            ;;
        4)
            list_environments
            ;;
        5)
            echo -e "${YELLOW}👋 Saliendo del script.${RESET}"
            break
            ;;
        *)
            echo -e "${RED}❌ Opción inválida.${RESET}"
            ;;
    esac

    echo ""
    read -p "Presioná [Enter] para continuar..."
done
