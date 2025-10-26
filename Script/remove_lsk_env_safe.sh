#!/bin/bash
# ========================================================
# Script: remove_lsk_env_safe.sh
# Autor: Gustavo Russo
# Descripción: Realiza backup y elimina la estructura Docker + LSK
# ========================================================

# --- Directorios base ---
DIR_DOCKER="/opt/docker"
DIR_APPS="/var/lsk"
BACKUP_DIR="/root/backups_lsk"

# --- Fecha y hora ---
DATE=$(date +"%Y%m%d_%H%M%S")

# --- Colores ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${YELLOW}🧭 Preparando eliminación del entorno LSK...${RESET}"
echo -e "Se harán copias de seguridad en: ${GREEN}$BACKUP_DIR${RESET}"
echo ""
echo -e "${YELLOW}⚠️  Este script eliminará las carpetas:${RESET}"
echo -e "   ${RED}$DIR_DOCKER${RESET}"
echo -e "   ${RED}$DIR_APPS${RESET}"
echo ""
read -p "¿Querés continuar y hacer backup antes de borrar? (escribí 'SI' para confirmar): " CONFIRM

if [ "$CONFIRM" != "SI" ]; then
    echo -e "${RED}❌ Operación cancelada.${RESET}"
    exit 1
fi

# Crear carpeta de backups si no existe
mkdir -p "$BACKUP_DIR"

# Backup de /opt/docker
if [ -d "$DIR_DOCKER" ]; then
    echo -e "${YELLOW}📦 Creando backup de $DIR_DOCKER...${RESET}"
    tar -czf "$BACKUP_DIR/docker_backup_$DATE.tar.gz" "$DIR_DOCKER" 2>/dev/null
    echo -e "${GREEN}✅ Backup creado: $BACKUP_DIR/docker_backup_$DATE.tar.gz${RESET}"
else
    echo -e "${YELLOW}⚠️  No existe: $DIR_DOCKER${RESET}"
fi

# Backup de /var/lsk
if [ -d "$DIR_APPS" ]; then
    echo -e "${YELLOW}📦 Creando backup de $DIR_APPS...${RESET}"
    tar -czf "$BACKUP_DIR/lsk_backup_$DATE.tar.gz" "$DIR_APPS" 2>/dev/null
    echo -e "${GREEN}✅ Backup creado: $BACKUP_DIR/lsk_backup_$DATE.tar.gz${RESET}"
else
    echo -e "${YELLOW}⚠️  No existe: $DIR_APPS${RESET}"
fi

echo ""
echo -e "${YELLOW}🧹 Eliminando carpetas...${RESET}"

# Eliminar directorios
if [ -d "$DIR_DOCKER" ]; then
    rm -rf "$DIR_DOCKER"
    echo -e "${GREEN}✅ Eliminado: $DIR_DOCKER${RESET}"
fi

if [ -d "$DIR_APPS" ]; then
    rm -rf "$DIR_APPS"
    echo -e "${GREEN}✅ Eliminado: $DIR_APPS${RESET}"
fi

echo ""
echo -e "${GREEN}✨ Entorno LSK eliminado y respaldado exitosamente.${RESET}"
echo -e "Los backups se encuentran en: ${YELLOW}$BACKUP_DIR${RESET}"
ls -lh "$BACKUP_DIR"

