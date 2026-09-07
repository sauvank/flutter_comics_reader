# ComicStream — Directives pour Claude

## 🛡️ RÈGLE ABSOLUE DE SÉCURITÉ & CONFIDENTIALITÉ
Ce dépôt est public. **Il est strictement interdit de commiter ou divulguer des données privées :**
- ❌ **Secrets & Clés** : Aucun mot de passe, clé privée, token API, keystore (`.jks`, `.keystore`), ni compte de service (`service_account.json`).
- ❌ **Identifiants réels** : Aucun numéro de série ADB réel, nom d'utilisateur privé, ni adresse IP locale réelle.
- ✅ **Placeholders obligatoires** : Utiliser systématiquement des valeurs génériques :
  - IP locale : `192.168.1.100` (ou `192.168.1.x`)
  - Identifiant ADB : `0123456789ABCDEF`
  - Utilisateur : `user` (ou `admin`)
  - Chemins : `/media/comics/...` ou `/chemin/vers/vos/bd`

## 🛠️ Commandes & Validation Obligatoire
Avant chaque commit ou validation de code :
```bash
flutter analyze
flutter test
```

## 🏷️ Commits & Releases
- Adopter la convention **Conventional Commits** (`feat:`, `fix:`, `perf:`, `chore:`, `docs:`, etc.).
- Pour incrémenter la version, créer le tag et pousser : `./scripts/bump_and_push.sh [patch|minor|major]`

## 🔄 Synchronisation du Contexte & Documentation
À chaque évolution, ajout de fonctionnalité ou refonte technique :
- **Mettre à jour systématiquement** les fichiers de documentation correspondants dans `docs/` (`docs/CONTEXT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `README.md`).
- Veiller à ce que l'état d'avancement, les formats pris en charge et la structure des données reflètent toujours fidèlement le code réel.

