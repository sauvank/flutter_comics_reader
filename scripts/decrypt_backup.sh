#!/bin/bash

# ==============================================================================
# Script de déchiffrement GPG
# ==============================================================================

set -e

echo "=========================================="
echo "      🔓 DÉCHIFFREMENT D'ARCHIVE GPG      "
echo "=========================================="

if [ -z "$1" ]; then
    read -p "📦 Chemin du fichier chiffré (.tar.gz.gpg) : " ENCRYPTED_FILE
else
    ENCRYPTED_FILE="$1"
fi

if [ ! -f "$ENCRYPTED_FILE" ]; then
    echo "❌ Erreur : Le fichier '$ENCRYPTED_FILE' n'existe pas."
    exit 1
fi

if [ -z "$2" ]; then
    read -p "📂 Dossier de destination pour l'extraction [Défaut: .] : " DEST_DIR
    DEST_DIR=${DEST_DIR:-"."}
else
    DEST_DIR="$2"
fi

mkdir -p "$DEST_DIR"

echo ""
echo "⏳ Déchiffrement et extraction en cours vers '$DEST_DIR'..."
gpg --decrypt "$ENCRYPTED_FILE" | tar -xzf - -C "$DEST_DIR"

echo ""
echo "✅ Restauration terminée avec succès dans '$DEST_DIR' !"
