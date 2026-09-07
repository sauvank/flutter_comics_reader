# ComicStream — Directives pour Antigravity / Gemini (AGY)

## 🛡️ Sécurité & Confidentialité
- **Dépôt public** : Zéro secret, zéro mot de passe, zéro clé API, zéro keystore commité.
- **Anonymisation stricte** : Utiliser exclusivement des placeholders génériques (`192.168.1.100`, `user`, `0123456789ABCDEF`, `/media/comics/...`).
- **Notes locales** : Toujours vérifier que les notes privées sont ignorées dans `.gitignore`.

## 🧪 Validation & Tests
- Exécuter `flutter analyze` et `flutter test` avant tout commit.

## 📦 Conventions & Release
- Suivre **Conventional Commits**.
- Utiliser `./scripts/bump_and_push.sh` pour incrémenter et tagger les versions.

## 🔄 Mise à jour du Contexte & Documentation
- **Répercussion systématique** : Lors de tout changement fonctionnel, architectural ou d'infrastructure, mettre à jour immédiatement les fichiers de contexte correspondants (`docs/CONTEXT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `README.md`).

