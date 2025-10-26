#!/bin/bash
# ========================================================
# Script: remove_lsk_env.sh
# Autor: Gustavo Russo
# Descripción: Elimina toda la estructura creada por init_lsk_env.sh
# ========================================================

# --- Directorios base ---
DIR_DOCKER="/opt/docker"
DIR_APPS="/var/lsk"

# --- Colores para salida ---
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RESET="\033[0m"

echo -e "${YELLOW}⚠️  Este script eliminará las carpetas:${RESET}"
echo -e "   ${RED}$DIR_DOCKER${RESET}"
echo -e "   ${RED}$DIR_APPS${RESET}"
echo ""
read -p "¿Estás seguro de que querés continuar? (escribí 'SI' para confirmar): " CONFIRM

if [ "$CONFIRM" != "SI" ]; then
    echo -e "${RED}❌ Operación cancelada.${RESET}"
    exit 1
fi

echo -e "${YELLOW}🧹 Eliminando estructura Docker y LSK...${RESET}"

# Eliminar directorios si existen
if [ -d "$DIR_DOCKER" ]; then
    rm -rf "$DIR_DOCKER"
    echo -e "${GREEN}✅ Eliminado: $DIR_DOCKER${RESET}"
else
    echo -e "${YELLOW}⚠️  No existe: $DIR_DOCKER${RESET}"
fi

if [ -d "$DIR_APPS" ]; then
    rm -rf "$DIR_APPS"
    echo -e "${GREEN}✅ Eliminado: $DIR_APPS${RESET}"
else
    echo -e "${YELLOW}⚠️  No existe: $DIR_APPS${RESET}"
fi

echo ""
echo -e "${GREEN}✨ Limpieza completada. El entorno LSK fue eliminado.${RESET}"
