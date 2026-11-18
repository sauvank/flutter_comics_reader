import 'package:flutter/material.dart';

import '../utils/desktop_layout.dart';
import '../l10n/l10n.dart';

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

    return DesktopContent(
      maxWidth: 860,
      child: ListView(
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
                  l10n.guideHeroTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.guideHeroBody,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAddServer,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addServer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.howItWorks,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _Step(
            number: 1,
            title: l10n.guideStep1Title,
            body: l10n.guideStep1Body,
          ),
          _Step(
            number: 2,
            title: l10n.guideStep2Title,
            body: l10n.guideStep2Body,
          ),
          _Step(
            number: 3,
            title: l10n.guideStep3Title,
            body: l10n.guideStep3Body,
          ),
          _Step(
            number: 4,
            title: l10n.guideStep4Title,
            body: l10n.guideStep4Body,
            isLast: true,
          ),
          const SizedBox(height: 16),
          Text(l10n.configurationExamples,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _Example(
            icon: Icons.cloud_outlined,
            title: 'WebDAV',
            subtitle: l10n.webdavSubtitle,
            fields: [
              (l10n.type, 'WebDAV'),
              (l10n.host, '192.168.1.100'),
              (l10n.port, l10n.webdavPorts),
              (l10n.path, '/comics ou /remote.php/dav/files/user'),
              (l10n.credentials, l10n.webdavCredentials),
            ],
            tip: l10n.webdavTip,
          ),
          _Example(
            icon: Icons.public_rounded,
            title: 'HTTP',
            subtitle: l10n.httpSubtitle,
            fields: [
              (l10n.type, 'HTTP'),
              (l10n.host, l10n.computerIp),
              (l10n.port, '8080'),
              (l10n.path, '/'),
              (l10n.credentials, l10n.noneLower),
            ],
            tip: l10n.httpTip,
          ),
          _Example(
            icon: Icons.swap_vert_rounded,
            title: 'FTP',
            subtitle: l10n.ftpSubtitle,
            fields: [
              (l10n.type, 'FTP'),
              (l10n.host, '192.168.1.100'),
              (l10n.port, '21'),
              (l10n.path, '/comics'),
              (l10n.credentials, l10n.ftpCredentials),
            ],
            tip: l10n.ftpTip,
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
                        child: Text(l10n.cannotConnectTitle,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Bullet(l10n.tipSameWifi),
                  _Bullet(l10n.tipUseIp),
                  _Bullet(l10n.tipFirewall),
                  _Bullet(l10n.tipVpn),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onImportConfiguration,
            icon: const Icon(Icons.file_download_outlined),
            label: Text(l10n.importExistingConfiguration),
          ),
        ],
      ),
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
