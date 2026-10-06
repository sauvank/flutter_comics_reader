import 'package:flutter/material.dart';

/// Step-by-step guide shown in the Server tab while no server is configured.
class ServerSetupGuide extends StatelessWidget {
  const ServerSetupGuide({
    super.key,
    required this.onAddServer,
    required this.onImportConfiguration,
  });

  final VoidCallback onAddServer;
  final VoidCallback onImportConfiguration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.dns_rounded,
                  size: 36, color: scheme.onPrimaryContainer),
              const SizedBox(height: 12),
              Text(
                'Lisez les BD de votre ordinateur ou NAS',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Un serveur rend votre collection accessible depuis le téléphone, sans tout copier. Comptez environ 2 minutes.',
                style: TextStyle(color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddServer,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un serveur'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Comment faire',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const _Step(
          number: 1,
          title: 'Partagez votre dossier de BD',
          body:
              'Sur votre NAS ou ordinateur, activez un partage WebDAV, FTP ou HTTP qui pointe vers le dossier contenant vos fichiers CBZ, CBR, PDF ou EPUB. Les exemples ci-dessous détaillent chaque cas.',
        ),
        const _Step(
          number: 2,
          title: 'Notez son adresse',
          body:
              'Repérez l’adresse IP locale de la machine (ex. 192.168.1.100) et le port du partage. Le téléphone doit être connecté au même réseau Wi-Fi.',
        ),
        const _Step(
          number: 3,
          title: 'Remplissez le formulaire',
          body:
              'Touchez « Ajouter un serveur », choisissez le type, puis saisissez l’hôte, le port, le chemin du dossier et, si besoin, l’identifiant et le mot de passe.',
        ),
        const _Step(
          number: 4,
          title: 'Testez puis enregistrez',
          body:
              '« Tester » vérifie la connexion. Une fois validé, « Enregistrer » ouvre directement le serveur pour parcourir et télécharger vos livres.',
          isLast: true,
        ),
        const SizedBox(height: 16),
        Text('Exemples de configuration',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _Example(
          icon: Icons.cloud_outlined,
          title: 'WebDAV',
          subtitle: 'Recommandé · NAS Synology, QNAP, Nextcloud',
          fields: [
            ('Type', 'WebDAV'),
            ('Hôte', '192.168.1.100'),
            ('Port', '5005 (Synology), 80 ou 443'),
            ('Chemin', '/comics ou /remote.php/dav/files/user'),
            ('Identifiants', 'ceux de votre compte NAS'),
          ],
          tip:
              'Sur Synology : installez « WebDAV Server » depuis le Centre de paquets et activez HTTP ou HTTPS.',
        ),
        const _Example(
          icon: Icons.public_rounded,
          title: 'HTTP',
          subtitle: 'Le plus simple depuis un ordinateur',
          fields: [
            ('Type', 'HTTP'),
            ('Hôte', 'IP de l’ordinateur'),
            ('Port', '8080'),
            ('Chemin', '/'),
            ('Identifiants', 'aucun'),
          ],
          tip:
              'Dans le dossier de vos BD, lancez « python3 -m http.server 8080 », ou le script server_example/comic_server.py fourni avec ComicStream.',
        ),
        const _Example(
          icon: Icons.swap_vert_rounded,
          title: 'FTP',
          subtitle: 'Box internet, anciens NAS',
          fields: [
            ('Type', 'FTP'),
            ('Hôte', '192.168.1.100'),
            ('Port', '21'),
            ('Chemin', '/comics'),
            ('Identifiants', 'compte FTP de la box ou du NAS'),
          ],
          tip:
              'Le FTP n’est pas chiffré : réservez-le à votre réseau domestique.',
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: scheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Ça ne se connecte pas ?',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _Bullet(
                    'Vérifiez que le téléphone et le serveur sont sur le même Wi-Fi.'),
                const _Bullet(
                    'Essayez l’adresse IP plutôt qu’un nom (nas.local).'),
                const _Bullet(
                    'Vérifiez que le pare-feu de l’ordinateur autorise le port choisi.'),
                const _Bullet(
                    'Hors de chez vous, passez par un VPN (WireGuard, Tailscale…) plutôt que d’exposer le serveur sur Internet.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onImportConfiguration,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Importer une configuration existante'),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text('$number',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Example extends StatelessWidget {
  const _Example({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.tip,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, String)> fields;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in fields)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Text(value,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(tip,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
