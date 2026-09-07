# ComicStream — Directives pour Agents Autonomes (AGY, Codex, etc.)

## 🛡️ RÈGLE ABSOLUE : SÉCURITÉ & ZÉRO DONNÉE PRIVÉE
Ce projet est un logiciel open-source public.
1. **Zéro Donnée Privée** :
   - Ne jamais introduire ni commiter de mots de passe, tokens, clés d'API, secrets ou certificats de signature.
   - Ne jamais insérer de vraies adresses IP locales (`192.168.1.12`), noms d'utilisateurs système (`pi`, `balkhubam`), numéros de série ADB matériels ou chemins réseau réels.
   - Toujours utiliser les placeholders standards : `192.168.1.100`, `user`, `0123456789ABCDEF`, `/media/comics/...`.
2. **Notes Privées & Credentials** :
   - Tout fichier contenant des notes locales privées doit être ignoré par `.gitignore` (`.private.md`, `SECURITY_CONTEXT.md`, etc.).

## 🧪 Tests & Qualité
Toute modification doit être validée par :
```bash
flutter analyze
flutter test
```

## 🚀 Workflow de Release
- Incrémentation automatique de version & tag Git : `./scripts/bump_and_push.sh`
