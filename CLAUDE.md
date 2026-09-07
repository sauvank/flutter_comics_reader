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
