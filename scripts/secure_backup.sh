#!/bin/bash

# ==============================================================================
# Script de chiffrement sécurisé GPG (Conserve les originaux intacts)
# ==============================================================================

set -e

echo "=========================================="
echo "      🔒 CHIFFREMENT DE DOSSIER GPG       "
echo "=========================================="

# 1. Dossier source à chiffrer
if [ -z "$1" ]; then
    read -p "📂 Chemin du dossier à chiffrer (ex: /home/balkhubam/comics) : " SOURCE_DIR
else
    SOURCE_DIR="$1"
fi

# Vérifier que le dossier source existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Erreur : Le dossier '$SOURCE_DIR' n'existe pas."
    exit 1
fi

# 2. Dossier de destination pour l'archive chiffrée
if [ -z "$2" ]; then
    read -p "💾 Dossier de destination (ex: /home/balkhubam/backups) [Défaut: ./backups] : " DEST_DIR
    DEST_DIR=${DEST_DIR:-"./backups"}
else
    DEST_DIR="$2"
fi

mkdir -p "$DEST_DIR"

# 3. Choix du mode de chiffrement (Clé PGP ou Mot de passe)
echo ""
echo "Choisissez la méthode de chiffrement :"
echo "1) Clé publique GPG (Recommandé - Asymétrique)"
echo "2) Mot de passe sécurisé (Symétrique AES-256)"
read -p "Votre choix (1 ou 2) [Défaut: 1] : " METHOD_CHOICE
METHOD_CHOICE=${METHOD_CHOICE:-1}

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
FOLDER_NAME=$(basename "$SOURCE_DIR")
OUTPUT_FILE="$DEST_DIR/${FOLDER_NAME}_encrypted_${TIMESTAMP}.tar.gz.gpg"

echo ""
echo "⏳ Chiffrement en cours de '$SOURCE_DIR'..."
echo "ℹ️  Rappel : Vos fichiers originaux restent intacts."

if [ "$METHOD_CHOICE" == "1" ]; then
    # Liste des clés GPG disponibles
    echo ""
    echo "Clés GPG disponibles sur ce système :"
    gpg --list-public-keys --keyid-format SHORT 2>/dev/null | grep -E "pub|uid" || true
    echo ""
    read -p "🔑 Email ou ID du destinataire GPG : " RECIPIENT
    
    # Exécution du chiffrement asymétrique
    tar -czf - -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" | \
    gpg --encrypt --recipient "$RECIPIENT" --trust-model always -o "$OUTPUT_FILE"
else
    # Exécution du chiffrement symétrique par mot de passe
    tar -czf - -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" | \
    gpg --symmetric --cipher-algo AES256 -o "$OUTPUT_FILE"
fi

echo ""
echo "=========================================="
echo "✅ Chiffrement terminé avec succès !"
echo "📦 Fichier chiffré généré :"
echo "   👉 $OUTPUT_FILE"
echo "📏 Taille : $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "=========================================="
