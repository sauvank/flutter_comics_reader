#!/bin/bash

# ==============================================================================
# Script de Synchronisation Incrémentale Chiffrée (Rclone Crypt -> Mega)
# ==============================================================================

set -e

# Couleurs d'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   🚀 SYNCHRONISATION INCRÉMENTALE CHIFFRÉE (RCLONE)   ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. Vérification de la présence de rclone
if ! command -v rclone &> /dev/null; then
    echo -e "${YELLOW}⚠️ Rclone n'est pas installé sur ce système.${NC}"
    read -p "Souhaitez-vous installer rclone automatiquement ? (o/n) [Défaut: o] : " INSTALL_RCLONE
    INSTALL_RCLONE=${INSTALL_RCLONE:-o}
    if [[ "$INSTALL_RCLONE" =~ ^[oOyY]$ ]]; then
        echo -e "${BLUE}Installation de rclone...${NC}"
        sudo apt update && sudo apt install -y rclone || sudo curl https://rclone.org/install.sh | sudo bash
    else
        echo -e "${RED}❌ Rclone est requis pour exécuter ce script.${NC}"
        exit 1
    fi
fi

# 2. Dossier source local
if [ -d "/mnt/books" ]; then
    DEFAULT_SOURCE="/mnt/books"
else
    DEFAULT_SOURCE="/mnt/bd"
fi

if [ -z "$1" ]; then
    echo ""
    read -p "📂 Chemin du dossier source à synchroniser [Défaut: $DEFAULT_SOURCE] : " SOURCE_PATH
    SOURCE_PATH=${SOURCE_PATH:-$DEFAULT_SOURCE}
else
    SOURCE_PATH="$1"
fi

if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "${RED}❌ Erreur : Le dossier source '$SOURCE_PATH' n'existe pas ou n'est pas monté.${NC}"
    echo "💡 Rappel : Si c'est un partage réseau (\\\\192.168.1.12\\...), montez-le d'abord dans /mnt/books"
    exit 1
fi

# 2.1 Sécurité anti-erreur sur les dossiers racines ou disques complets
CLEAN_SOURCE=$(realpath -m "$SOURCE_PATH" 2>/dev/null || echo "$SOURCE_PATH")
FORBIDDEN_PATHS=("/" "/mnt" "/mnt/c" "/mnt/wsl" "/mnt/wslg" "/home" "/root" "/etc" "/usr" "/var" "/tmp" "/bin" "/sbin" "/lib" "/opt" "/sys" "/proc" "/dev")

for forbidden in "${FORBIDDEN_PATHS[@]}"; do
    if [ "$CLEAN_SOURCE" == "$forbidden" ]; then
        echo ""
        echo -e "${RED}🛑 SÉCURITÉ ACTIVÉE : Le chemin '$SOURCE_PATH' est interdit !${NC}"
        echo -e "${RED}❌ Vous tentez de synchroniser une racine système ou le disque Windows complet.${NC}"
        echo -e "${YELLOW}💡 Veuillez spécifier votre dossier de BD précis (ex: /mnt/bd).${NC}"
        exit 1
    fi
done

# 3. Choix du remote chiffré (Défaut: terabox_crypt)
REMOTE_NAME="terabox_crypt"
if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo ""
    echo -e "${YELLOW}⚠️ Le remote chiffré '${REMOTE_NAME}:' n'est pas encore configuré dans rclone.${NC}"
    echo "Souhaitez-vous lancer la configuration guidée maintenant ?"
    read -p "(o/n) [Défaut: o] : " DO_CONFIG
    DO_CONFIG=${DO_CONFIG:-o}
    if [[ "$DO_CONFIG" =~ ^[oOyY]$ ]]; then
        echo ""
        echo -e "${BLUE}➡️ Lancement de 'rclone config'...${NC}"
        echo "Suivez les étapes :"
        echo "  1. Créez votre remote 'mega' (Type: mega)"
        echo "  2. Créez votre remote '${REMOTE_NAME}' (Type: crypt, pointant vers 'mega:Comics')"
        rclone config
    else
        echo -e "${RED}Configuration annulée.${NC}"
        exit 1
    fi
fi

# 4. Lancement de la synchronisation chiffrée
echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}⏳ Début de la synchronisation chiffrée...${NC}"
echo -e "   Source      : ${YELLOW}$SOURCE_PATH${NC}"
echo -e "   Destination : ${YELLOW}${REMOTE_NAME}:${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Options :
# -P : Affichage de la progression en temps réel
# --track-renames : Détecte les fichiers renommés/déplacés et les renomme sur le cloud sans ré-upload
# --fast-list : Optimise les requêtes pour lister les fichiers
# --transfers 2 : Téléverse 2 gros fichiers en parallèle
# --tpslimit 5 : Limite le nombre de requêtes par seconde pour éviter les blocages API
# --retries 5 : Réessaie automatiquement les fichiers en échec
# --low-level-retries 10 : Réessaie les paquets/requêtes individuelles
# --timeout 30m : Laisse le temps pour les très gros fichiers
rclone sync "$SOURCE_PATH" "${REMOTE_NAME}:" \
    --progress \
    --track-renames \
    --transfers 2 \
    --tpslimit 5 \
    --checkers 4 \
    --retries 5 \
    --low-level-retries 10 \
    --retries-sleep 3s \
    --timeout 30m \
    --buffer-size 64M \
    --fast-list

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}✅ Synchronisation chiffrée terminée avec succès !${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""
echo -e "${BLUE}ℹ️ Vos fichiers sont stockés 100% chiffrés sur Mega.${NC}"
echo -e "${BLUE}ℹ️ Alist sur votre VPS peut désormais les déchiffrer à la volée pour votre application.${NC}"
