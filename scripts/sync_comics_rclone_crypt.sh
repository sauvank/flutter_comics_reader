#!/bin/bash

# ==============================================================================
# Script de Synchronisation Carbone Chiffrée (Rclone Crypt -> TeraBox)
# ==============================================================================

set -e

# Couleurs d'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   🚀 COPIE CARBONE CHIFFRÉE (MIROIR RCLONE)          ${NC}"
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

# 2.1 Sécurité anti-erreur sur les dossiers racines ou disques complets
CLEAN_SOURCE=$(realpath -m "$SOURCE_PATH" 2>/dev/null || echo "$SOURCE_PATH")
FORBIDDEN_PATHS=("/" "/mnt" "/mnt/c" "/mnt/wsl" "/mnt/wslg" "/home" "/root" "/etc" "/usr" "/var" "/tmp" "/bin" "/sbin" "/lib" "/opt" "/sys" "/proc" "/dev")

for forbidden in "${FORBIDDEN_PATHS[@]}"; do
    if [ "$CLEAN_SOURCE" == "$forbidden" ]; then
        echo ""
        echo -e "${RED}🛑 SÉCURITÉ ACTIVÉE : Le chemin '$SOURCE_PATH' est interdit !${NC}"
        echo -e "${RED}❌ Vous tentez de synchroniser une racine système ou le disque Windows complet.${NC}"
        echo -e "${YELLOW}💡 Veuillez spécifier votre dossier de BD précis (ex: /mnt/books).${NC}"
        exit 1
    fi
done

# 2.2 Vérification et montage automatique si /mnt/books
if [ "$SOURCE_PATH" == "/mnt/books" ]; then
    if [ -z "$(ls -A /mnt/books 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠️ /mnt/books n'est pas monté. Tentative de montage CIFS automatique...${NC}"
        sudo mount /mnt/books 2>/dev/null || \
        sudo mount -t cifs //192.168.1.100/public/misc/BOOKS /mnt/books -o credentials=/etc/cifs-credentials,vers=3.0,uid=1000,gid=1000,_netdev 2>/dev/null || \
        sudo mount -t cifs //192.168.1.100/public/misc/BOOKS /mnt/books -o credentials="$HOME/.cifs-credentials",vers=3.0,uid=1000,gid=1000 2>/dev/null || true
    fi
fi

# 2.3 CONTRÔLE DE SÉCURITÉ STRICT : Dossier inaccessible ou vide
if [ ! -d "$SOURCE_PATH" ]; then
    echo ""
    echo -e "${RED}❌ ERREUR CRITIQUE : Le dossier source '$SOURCE_PATH' est INTROUVABLE ou NON ACCESSIBLE.${NC}"
    echo -e "${RED}🛑 La synchronisation miroir est stoppée immédiatement pour protéger vos données distantes.${NC}"
    exit 1
fi

FILE_COUNT=$(find "$SOURCE_PATH" -maxdepth 2 -type f -o -type d 2>/dev/null | wc -l)
if [ "$FILE_COUNT" -le 1 ]; then
    echo ""
    echo -e "${RED}❌ ERREUR CRITIQUE : Le dossier '$SOURCE_PATH' est TOTALEMENT VIDE ou déconnecté du réseau.${NC}"
    echo -e "${RED}🛑 Opération annulée pour empêcher toute suppression accidentelle sur TeraBox.${NC}"
    echo -e "${YELLOW}💡 Vérifiez que le NAS //192.168.1.100 est allumé et monté sur /mnt/books.${NC}"
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
        rclone config
    else
        echo -e "${RED}Configuration annulée.${NC}"
        exit 1
    fi
fi

# 4. Conversion automatique des fichiers PDF en CBZ (Optimisation ComicStream)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF_CONVERTER="$SCRIPT_DIR/convert_pdf_to_cbz.py"

# Vérification des PDF présents dans le dossier source
PDF_COUNT=$(find "$SOURCE_PATH" -type f \( -iname "*.pdf" \) 2>/dev/null | wc -l)

if [ "$PDF_COUNT" -gt 0 ]; then
    echo ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${YELLOW}📄 Détection de ${PDF_COUNT} fichier(s) PDF à convertir en CBZ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "ℹ️  ComicStream fonctionne de façon optimale avec les archives CBZ."
    echo -e "   Conversion automatique avant le téléversement distant..."

    # Vérification des outils de conversion (pdftoppm, unar, 7z)
    if ! command -v pdftoppm &> /dev/null || (! command -v unar &> /dev/null && ! command -v 7z &> /dev/null); then
        echo -e "${YELLOW}⚠️ Des outils de conversion (poppler-utils, unar) sont manquants.${NC}"
        read -p "Souhaitez-vous les installer automatiquement ? (o/n) [Défaut: o] : " INSTALL_TOOLS
        INSTALL_TOOLS=${INSTALL_TOOLS:-o}
        if [[ "$INSTALL_TOOLS" =~ ^[oOyY]$ ]]; then
            sudo apt update && sudo apt install -y poppler-utils unar p7zip-full
        else
            echo -e "${RED}❌ Impossible de convertir les fichiers sans ces outils.${NC}"
            read -p "Poursuivre la synchronisation sans convertir ? (o/n) [Défaut: n] : " CONTINUE_ANYWAY
            CONTINUE_ANYWAY=${CONTINUE_ANYWAY:-n}
            if [[ ! "$CONTINUE_ANYWAY" =~ ^[oOyY]$ ]]; then
                exit 1
            fi
        fi
    fi

    if [ -f "$PDF_CONVERTER" ]; then
        PYTHONUNBUFFERED=1 python3 -u "$PDF_CONVERTER" "$SOURCE_PATH"
    else
        echo -e "${RED}❌ Script convert_pdf_to_cbz.py introuvable dans $SCRIPT_DIR.${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${GREEN}✅ Aucun fichier PDF à convertir (Bibliothèque 100% CBZ/CBR/Images prête).${NC}"
fi

# 5. Lancement de la synchronisation carbone (Miroir)
echo ""
echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}⏳ Lancement de la copie carbone chiffrée (Miroir)...${NC}"
echo -e "   Source locale : ${YELLOW}$SOURCE_PATH${NC} (Accessible ✅)"
echo -e "   Destination   : ${YELLOW}${REMOTE_NAME}:${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Options :
# sync : Copie carbone exacte (miroir parfait de la source vers le distant)
# -P : Affichage de la progression en temps réel
# --stats 3s : Actualisation de la vitesse et des fichiers toutes les 3 secondes
# --fast-list : Optimise les requêtes pour lister les fichiers
# --transfers 2 : Téléverse 2 gros fichiers en parallèle
# --tpslimit 5 : Limite le nombre de requêtes par seconde pour éviter les blocages API
# --retries 5 : Réessaie automatiquement les fichiers en échec
# --low-level-retries 10 : Réessaie les paquets/requêtes individuelles
# --timeout 30m : Laisse le temps pour les très gros fichiers
rclone sync "$SOURCE_PATH" "${REMOTE_NAME}:" \
    --progress \
    --stats 3s \
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
echo -e "${GREEN}✅ Copie carbone terminée avec succès !${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""
echo -e "${BLUE}ℹ️ Vos fichiers distants sont désormais le miroir parfait de votre dossier local.${NC}"
echo -e "${BLUE}ℹ️ Alist / WebDAV sert votre collection à jour pour ComicStream.${NC}"

