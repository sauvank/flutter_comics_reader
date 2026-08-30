import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_version.dart';
import '../providers/library_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/reader_settings_service.dart';
import '../services/update_service.dart';
import '../utils/format_utils.dart';
import '../widgets/reader_controls.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isCheckingUpdate = false;

  Future<void> _checkUpdateManual() async {
    if (_isCheckingUpdate) return;
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final info = await UpdateService().checkUpdate();
      if (!mounted) return;

      if (info != null && info.hasUpdate) {
        UpdateService().promptUpdateDialog(context, info);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Text('ComicStream est à jour (${AppVersion.fullVersion}) !'),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  void _clearCoversCache(BuildContext context) async {
    final db = DatabaseService();
    final coversDir = await db.getCoversDirectory();
    if (await coversDir.exists()) {
      final files = coversDir.listSync();
      for (final f in files) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache des couvertures vidé avec succès !')),
      );
    }
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout supprimer ?'),
        content: const Text(
          'Cette action supprimera toutes les BDs et mangas téléchargés en local pour libérer de l\'espace. Vos paramètres de serveurs seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final library = context.read<LibraryProvider>();
              final books = List.from(library.books);
              for (final b in books) {
                await library.deleteBook(b.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tous les fichiers locaux ont été supprimés.')),
                );
              }
            },
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
  }

  void _showServerGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 10),
                const Text('Guide Serveur Local', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Option 1 : Serveur WebDAV Docker (Recommandé)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lancez un serveur WebDAV léger avec Docker en 1 ligne en pointant vers votre dossier de BDs :',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'docker run -d -p 8080:80 -v /chemin/vers/vos/bds:/var/webdav/public bytemark/webdav',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Option 2 : Script Python prêt à l\'emploi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Un serveur Python dédié est fourni dans le dossier `server_example/comic_server.py`. Pour le lancer :',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'python3 server_example/comic_server.py --port 8080 --dir ~/Comics',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Option 3 : NAS Synology / TrueNAS / Nextcloud',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 6),
            const Text(
              'Activez simplement le service WebDAV dans le panneau d\'administration de votre NAS (port 5005 par défaut sur Synology) et entrez vos identifiants dans l\'application.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final readerSettings = context.watch<ReaderSettingsService>();
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.settings_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Paramètres'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
          // Theme Section
          _buildSectionHeader('Apparence & Thème', theme),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thème de l\'application', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text('Sombre'),
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.oled,
                      label: Text('OLED'),
                      icon: Icon(Icons.contrast_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text('Clair'),
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                    ),
                  ],
                  selected: {themeProvider.mode},
                  onSelectionChanged: (set) => themeProvider.setThemeMode(set.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Reading Preferences Section
          _buildSectionHeader('Préférences du lecteur', theme),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Mode de lecture par défaut'),
                  subtitle: Text(
                    readerSettings.readingMode == ReadingMode.leftToRight
                        ? 'BD / Franco-Belge (Gauche à Droite)'
                        : readerSettings.readingMode == ReadingMode.rightToLeft
                            ? 'Manga (Droite à Gauche)'
                            : 'Webtoon (Défilement vertical)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ReaderSettingsSheet(settings: readerSettings),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.screen_lock_portrait_outlined),
                  title: const Text('Garder l\'écran actif en lecture'),
                  value: readerSettings.keepScreenOn,
                  onChanged: (val) => readerSettings.setKeepScreenOn(val),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.pin_outlined),
                  title: const Text('Afficher le numéro de page'),
                  value: readerSettings.showPageNumbers,
                  onChanged: (val) => readerSettings.setShowPageNumbers(val),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Convertir automatiquement les PDF en CBZ'),
                  subtitle: const Text(
                    'Transforme chaque PDF téléchargé en archive BD ultra-fluide pour tablette.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: readerSettings.autoConvertPdfToCbz,
                  onChanged: (val) => readerSettings.setAutoConvertPdfToCbz(val),
                ),
                if (readerSettings.autoConvertPdfToCbz) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.high_quality_rounded, color: Color(0xFF8B5CF6)),
                    title: const Text('Qualité de rendu BD'),
                    subtitle: Text(
                      readerSettings.pdfRenderQuality == PdfRenderQuality.autoAdaptive
                          ? 'Automatique (Détecte l\'écran + 35% de netteté)'
                          : readerSettings.pdfRenderQuality == PdfRenderQuality.highSuperSampled
                              ? 'Super-échantillonné (2600px - Zoom net)'
                              : readerSettings.pdfRenderQuality == PdfRenderQuality.ultraHd
                                  ? 'Ultra HD (3500px - Définition max)'
                                  : 'Standard 1:1 (1900px - Rapide)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: DropdownButton<PdfRenderQuality>(
                      value: readerSettings.pdfRenderQuality,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(
                          value: PdfRenderQuality.autoAdaptive,
                          child: Text('Auto (Écran + 35%)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: PdfRenderQuality.highSuperSampled,
                          child: Text('Élevée (2600px)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: PdfRenderQuality.ultraHd,
                          child: Text('Ultra HD (3500px)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: PdfRenderQuality.screenMatch,
                          child: Text('Standard 1:1', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          readerSettings.setPdfRenderQuality(val);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Storage Section
          _buildSectionHeader('Stockage & Cache', theme),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Espace occupé par les livres :', style: TextStyle(fontSize: 14)),
                    Text(
                      FormatUtils.formatBytes(library.totalStorageBytes),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${library.books.length} livre(s) téléchargé(s)',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _clearCoversCache(context),
                        icon: const Icon(Icons.cleaning_services, size: 16),
                        label: const Text('Vider cache', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () => _confirmDeleteAll(context),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                        label: const Text('Tout effacer', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Updates Section
          _buildSectionHeader('Mises à jour', theme),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.system_update_rounded, color: theme.colorScheme.primary, size: 22),
              ),
              title: const Text('Rechercher une mise à jour'),
              subtitle: Text(
                'Version installée : ${AppVersion.fullVersion}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: _isCheckingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilledButton.tonal(
                      onPressed: () => _checkUpdateManual(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Vérifier', style: TextStyle(fontSize: 12)),
                    ),
              onTap: _isCheckingUpdate ? null : () => _checkUpdateManual(),
            ),
          ),
          const SizedBox(height: 18),

          // Guide & Help
          _buildSectionHeader('Aide & Configuration', theme),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.help_center_outlined, color: Color(0xFF06B6D4)),
              title: const Text('Comment configurer mon serveur local ?'),
              subtitle: const Text('Docker, Python, NAS Synology, TrueNAS...', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showServerGuide(context),
            ),
          ),
          const SizedBox(height: 24),

          // App Info & Version
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(40)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'ComicStream ${AppVersion.fullVersion}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lecteur de BD, Comics & Mangas Cloud',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
