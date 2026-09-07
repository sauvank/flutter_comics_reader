#!/usr/bin/env bash
set -euo pipefail

# Déterminer la racine du projet
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

PUBSPEC_FILE="$REPO_DIR/pubspec.yaml"
APP_VERSION_FILE="$REPO_DIR/lib/constants/app_version.dart"

if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "❌ Erreur: $PUBSPEC_FILE introuvable."
    exit 1
fi

# Lire la version actuelle dans pubspec.yaml (ex: 1.1.21+53)
CURRENT_LINE=$(grep "^version:" "$PUBSPEC_FILE")
CURRENT_FULL_VERSION=$(echo "$CURRENT_LINE" | sed -E 's/version:[[:space:]]*//; s/[[:space:]]*$//')

# Extraire version et build number
VERSION_PART="${CURRENT_FULL_VERSION%+*}"
BUILD_PART="${CURRENT_FULL_VERSION#*+}"

if [ "$VERSION_PART" = "$CURRENT_FULL_VERSION" ] || [ -z "$BUILD_PART" ]; then
    BUILD_PART=1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_PART"

BUMP_TYPE="${1:-patch}"

case "$BUMP_TYPE" in
    patch)
        PATCH=$((PATCH + 1))
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    *)
        echo "Usage: $0 [patch|minor|major]"
        exit 1
        ;;
esac

NEW_BUILD=$((BUILD_PART + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_FULL_VERSION="$NEW_VERSION+$NEW_BUILD"
TAG_NAME="v$NEW_VERSION"

echo "=================================================="
echo "🚀 Incrémentation de version : $CURRENT_FULL_VERSION -> $NEW_FULL_VERSION"
echo "🏷️  Tag Git associé : $TAG_NAME"
echo "=================================================="

# 1. Mettre à jour pubspec.yaml
sed -i -E "s/^version:[[:space:]].*/version: $NEW_FULL_VERSION/" "$PUBSPEC_FILE"

# 2. Mettre à jour lib/constants/app_version.dart si présent
if [ -f "$APP_VERSION_FILE" ]; then
    sed -i -E "s/static const String version = '[^']*';/static const String version = '$NEW_VERSION';/" "$APP_VERSION_FILE"
    sed -i -E "s/static const int buildNumber = [0-9]+;/static const int buildNumber = $NEW_BUILD;/" "$APP_VERSION_FILE"
fi

# 3. Git commit & tag
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

git add "$PUBSPEC_FILE" "$APP_VERSION_FILE"
git commit -m "chore(version): bump version to $NEW_FULL_VERSION ($TAG_NAME)" || echo "Rien à commiter"

echo "📌 Création du tag $TAG_NAME..."
git tag -a "$TAG_NAME" -m "Release $TAG_NAME"

echo "⬆️  Push de la branche ($CURRENT_BRANCH) et des tags..."
git push origin "$CURRENT_BRANCH"
git push origin "$TAG_NAME"

echo ""
echo "✅ Déploiement et tag $TAG_NAME poussés avec succès !"
