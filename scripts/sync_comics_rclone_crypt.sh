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

# 2.2 Auto-montage du partage réseau si vide
if [ "$SOURCE_PATH" == "/mnt/books" ] && [ -z "$(ls -A /mnt/books 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️ Le dossier /mnt/books est vide. Tentative de montage réseau automatique...${NC}"
    sudo mount -t cifs //192.168.1.12/public/misc/BOOKS /mnt/books -o credentials=/etc/cifs-credentials-pi,vers=3.0,uid=1000,gid=1000,_netdev 2>/dev/null || \
    sudo mount -t cifs //192.168.1.12/public/misc/BOOKS /mnt/books -o user=pi,password="159753Etw43:).",vers=3.0,uid=1000,gid=1000 2>/dev/null || true
fi

# 2.3 Vérification que le dossier source n'est pas vide
if [ -z "$(ls -A "$SOURCE_PATH" 2>/dev/null)" ]; then
    echo -e "${RED}❌ Erreur : Le dossier source '$SOURCE_PATH' est totalement VIDE ou non monté.${NC}"
    echo "💡 Vérifiez que votre partage réseau Samba/NAS (//192.168.1.12/public/misc/BOOKS) est accessible."
    exit 1
fi

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
# copy : Copie incrémentale sécurisée (n'efface JAMAIS les fichiers existants sur le cloud)
# --fast-list : Optimise les requêtes pour lister les fichiers
# --transfers 2 : Téléverse 2 gros fichiers en parallèle
# --tpslimit 5 : Limite le nombre de requêtes par seconde pour éviter les blocages API
# --retries 5 : Réessaie automatiquement les fichiers en échec
# --low-level-retries 10 : Réessaie les paquets/requêtes individuelles
# --timeout 30m : Laisse le temps pour les très gros fichiers
rclone copy "$SOURCE_PATH" "${REMOTE_NAME}:" \
    --progress \
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
echo -e "${GREEN}✅ Téléversement sécurisé terminé avec succès !${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""
echo -e "${BLUE}ℹ️ Vos fichiers sont stockés 100% chiffrés sur le Cloud.${NC}"
echo -e "${BLUE}ℹ️ Aucun fichier distant n'a été supprimé.${NC}"
echo -e "${BLUE}ℹ️ Alist / WebDAV peut désormais les servir à votre application ComicStream.${NC}"
