import 'package:flutter/material.dart';
import '../utils/desktop_layout.dart';
import 'package:provider/provider.dart';
import '../constants/app_version.dart';
import '../providers/library_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../services/reader_settings_service.dart';
import '../services/update_service.dart';
import '../utils/format_utils.dart';
import 'package:flutter/services.dart';
import '../widgets/reader_controls.dart';
import 'account/account_screen.dart';
import '../l10n/l10n.dart';

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
                const Icon(Icons.check_circle_rounded,
                    color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Text(l10n.upToDate(AppVersion.fullVersion)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.updateCheckError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _clearCoversCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearCacheTitle),
        content: Text(l10n.clearCacheBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.empty)),
        ],
      ),
    );
    if (confirm != true) return;

    final db = DatabaseService();
    final coversDir = await db.getCoversDirectory();
    if (await coversDir.exists()) {
      final files = coversDir.listSync();
      for (final f in files) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.coverCacheCleared)),
      );
    }
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllTitle),
        content: Text(
          l10n.deleteAllBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final library = context.read<LibraryProvider>();
              final books = List.from(library.books);
              for (final b in books) {
                await library.deleteBook(b.id);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.allLocalFilesDeleted)),
                );
              }
            },
            child: Text(l10n.eraseAll),
          ),
        ],
      ),
    );
  }

  void _showServerGuide(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildCommandBox(String commandText) {
      return Container(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                commandText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: commandText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.commandCopied),
                      duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
      );
    }

    showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
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
                Icon(Icons.help_outline_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(l10n.localServerGuide,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const Divider(height: 24),
            Text(
              l10n.guideOption1,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guideOption1Body,
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            buildCommandBox(
                'docker run -d -p 8080:80 -v /chemin/vers/vos/bds:/var/webdav/public bytemark/webdav'),
            const SizedBox(height: 18),
            Text(
              l10n.guideOption2,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guideOption2Body,
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            buildCommandBox(
                'python3 server_example/comic_server.py --port 8080 --dir ~/Comics'),
            const SizedBox(height: 18),
            Text(
              l10n.guideOption3,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guideOption3Body,
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
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
              child: Icon(Icons.settings_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(l10n.settings),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSectionHeader(l10n.accountAndSyncShort, theme),
              Container(
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: Text(l10n.accountAndSync),
                  subtitle: Text(l10n.accountAndSyncSubtitle,
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountScreen())),
                ),
              ),
              const SizedBox(height: 18),
              // Theme Section
              _buildSectionHeader(l10n.appearanceTheme, theme),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.appTheme,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SegmentedButton<AppThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: AppThemeMode.dark,
                          label: Text(l10n.dark),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.oled,
                          label: Text('OLED'),
                          icon: Icon(Icons.contrast_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.light,
                          label: Text(l10n.light),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                      ],
                      selected: {themeProvider.mode},
                      onSelectionChanged: (set) =>
                          themeProvider.setThemeMode(set.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Reading Preferences Section
              _buildSectionHeader(l10n.readerPreferences, theme),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: Text(l10n.defaultReadingMode),
                      subtitle: Text(
                        readerSettings.readingMode == ReadingMode.leftToRight
                            ? l10n.readingModeComic
                            : readerSettings.readingMode ==
                                    ReadingMode.rightToLeft
                                ? l10n.readingModeManga
                                : l10n.readingModeWebtoon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showAdaptiveSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              ReaderSettingsSheet(settings: readerSettings),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary:
                          const Icon(Icons.screen_lock_portrait_outlined),
                      title: Text(l10n.keepScreenOn),
                      value: readerSettings.keepScreenOn,
                      onChanged: (val) => readerSettings.setKeepScreenOn(val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.pin_outlined),
                      title: Text(l10n.showPageNumber),
                      value: readerSettings.showPageNumbers,
                      onChanged: (val) =>
                          readerSettings.setShowPageNumbers(val),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.chrome_reader_mode_outlined),
                      title: Text(l10n.doublePageTitle),
                      subtitle: Text(l10n.doublePageBody,
                          style: const TextStyle(fontSize: 12)),
                      value: readerSettings.doublePage,
                      onChanged: (val) => readerSettings.setDoublePage(val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.auto_fix_high_rounded,
                          color: Color(0xFF8B5CF6)),
                      title: Text(l10n.autoConvertPdf),
                      subtitle: Text(
                        l10n.autoConvertPdfBody,
                        style: TextStyle(fontSize: 12),
                      ),
                      value: readerSettings.autoConvertPdfToCbz,
                      onChanged: (val) =>
                          readerSettings.setAutoConvertPdfToCbz(val),
                    ),
                    if (readerSettings.autoConvertPdfToCbz) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.high_quality_rounded,
                            color: Color(0xFF8B5CF6)),
                        title: Text(l10n.comicRenderQuality),
                        subtitle: Text(
                          readerSettings.pdfRenderQuality ==
                                  PdfRenderQuality.autoAdaptive
                              ? l10n.qualityAutoLong
                              : readerSettings.pdfRenderQuality ==
                                      PdfRenderQuality.highSuperSampled
                                  ? l10n.qualitySuperLong
                                  : readerSettings.pdfRenderQuality ==
                                          PdfRenderQuality.ultraHd
                                      ? l10n.qualityUltraLong
                                      : l10n.qualityStandardLong,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: DropdownButton<PdfRenderQuality>(
                          value: readerSettings.pdfRenderQuality,
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(12),
                          items: [
                            DropdownMenuItem(
                              value: PdfRenderQuality.autoAdaptive,
                              child: Text(l10n.qualityAuto,
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: PdfRenderQuality.highSuperSampled,
                              child: Text(l10n.qualityHigh,
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: PdfRenderQuality.ultraHd,
                              child: Text('Ultra HD (3500px)',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: PdfRenderQuality.screenMatch,
                              child: Text(l10n.qualityStandard,
                                  style: TextStyle(fontSize: 12)),
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

              // E-Books & EPUB Section
              _buildSectionHeader(l10n.ebooksEpub, theme),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fontSize,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Slider(
                      value: readerSettings.epubFontSize,
                      min: 12,
                      max: 32,
                      divisions: 20,
                      label: '${readerSettings.epubFontSize.toInt()} px',
                      onChanged: (val) => readerSettings.setEpubFontSize(val),
                    ),
                    const Divider(height: 24),
                    Text(l10n.font,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SegmentedButton<EpubFontFamily>(
                      segments: const [
                        ButtonSegment(
                            value: EpubFontFamily.sansSerif,
                            label: Text('Sans-serif')),
                        ButtonSegment(
                            value: EpubFontFamily.serif, label: Text('Serif')),
                        ButtonSegment(
                            value: EpubFontFamily.monospace,
                            label: Text('Mono')),
                      ],
                      selected: {readerSettings.epubFontFamily},
                      onSelectionChanged: (set) =>
                          readerSettings.setEpubFontFamily(set.first),
                    ),
                    const Divider(height: 24),
                    Text(l10n.lineSpacing,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: EpubLineHeight.values.map((val) {
                        final label = val == EpubLineHeight.compact
                            ? l10n.compact
                            : val == EpubLineHeight.normal
                                ? l10n.normal
                                : l10n.relaxed;
                        return ChoiceChip(
                          label: Text(label),
                          selected: readerSettings.epubLineHeight == val,
                          onSelected: (_) =>
                              readerSettings.setEpubLineHeight(val),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                    Text(l10n.margin,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: EpubMargin.values.map((val) {
                        final label = val == EpubMargin.narrow
                            ? l10n.narrowShort
                            : val == EpubMargin.normal
                                ? l10n.normal
                                : l10n.large;
                        return ChoiceChip(
                          label: Text(label),
                          selected: readerSettings.epubMargin == val,
                          onSelected: (_) => readerSettings.setEpubMargin(val),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.justifiedText,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      value:
                          readerSettings.epubTextAlign == EpubTextAlign.justify,
                      onChanged: (val) => readerSettings.setEpubTextAlign(
                          val ? EpubTextAlign.justify : EpubTextAlign.left),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Storage Section
              _buildSectionHeader(l10n.storageCache, theme),
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
                        Text(l10n.spaceUsedByBooks,
                            style: TextStyle(fontSize: 14)),
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
                      l10n.booksDownloadedCount(library.books.length),
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _clearCoversCache(context),
                            icon: const Icon(Icons.cleaning_services, size: 16),
                            label: Text(l10n.clearCache,
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                                foregroundColor: Colors.redAccent),
                            onPressed: () => _confirmDeleteAll(context),
                            icon: const Icon(Icons.delete_sweep_rounded,
                                size: 16),
                            label: Text(l10n.eraseAll,
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Updates Section
              _buildSectionHeader(l10n.updates, theme),
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
                    child: Icon(Icons.system_update_rounded,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  title: Text(l10n.checkForUpdate),
                  subtitle: Text(
                    l10n.installedVersion(AppVersion.fullVersion),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child:
                              Text(l10n.check, style: TextStyle(fontSize: 12)),
                        ),
                  onTap: _isCheckingUpdate ? null : () => _checkUpdateManual(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shop_two_rounded,
                        color: Color(0xFF10B981), size: 22),
                  ),
                  title: const Text('Google Play Store'),
                  subtitle: Text(l10n.seeStoreListing,
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => UpdateService().launchPlayStore(),
                ),
              ),
              const SizedBox(height: 18),

              // Guide & Help
              _buildSectionHeader(l10n.helpSetup, theme),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.help_center_outlined,
                      color: Color(0xFF06B6D4)),
                  title: Text(l10n.howToSetupLocalServer),
                  subtitle: Text(l10n.helpSetupSubtitle,
                      style: TextStyle(fontSize: 12)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(80),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                theme.colorScheme.outlineVariant.withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded,
                              size: 16, color: theme.colorScheme.primary),
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
                      l10n.appTagline,
                      style: TextStyle(
                          fontSize: 11, color: theme.colorScheme.outline),
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
