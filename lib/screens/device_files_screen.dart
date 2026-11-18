import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book_item.dart';
import '../providers/library_provider.dart';
import '../services/device_storage_access_service.dart';
import 'device_scan_results_screen.dart';
import 'synced_reader_screen.dart';
import '../l10n/l10n.dart';
import '../utils/desktop_layout.dart';
import '../utils/format_utils.dart';

/// Dedicated entry point for books already stored on the current device.
class DeviceFilesScreen extends StatefulWidget {
  const DeviceFilesScreen({super.key});

  @override
  State<DeviceFilesScreen> createState() => _DeviceFilesScreenState();
}

class _DeviceFilesScreenState extends State<DeviceFilesScreen>
    with WidgetsBindingObserver {
  bool _importing = false;
  bool _waitingForStorageAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForStorageAccess) {
      _waitingForStorageAccess = false;
      _completeStorageAccessRequest();
    }
  }

  Future<void> _scanDeviceStorage() async {
    if (!await DeviceStorageAccessService.hasAllFilesAccess()) {
      final shouldRequest = await _showStorageAccessExplanation();
      if (!shouldRequest || !mounted) return;
      _waitingForStorageAccess = true;
      final requested =
          await DeviceStorageAccessService.requestAllFilesAccess();
      if (!requested && mounted) {
        _waitingForStorageAccess = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allFilesAccessRequired),
          ),
        );
      } else if (await DeviceStorageAccessService.hasAllFilesAccess()) {
        _waitingForStorageAccess = false;
        await _scanDeviceStorage();
      }
      return;
    }

    final storagePath = await DeviceStorageAccessService.sharedStoragePath();
    if (storagePath == null || !mounted) return;
    await _scanAndReview(storagePath);
  }

  /// Scans [rootPath], lets the user pick the books to keep, then imports them.
  Future<void> _scanAndReview(String rootPath) async {
    setState(() => _importing = true);
    try {
      final paths =
          await context.read<LibraryProvider>().scanLocalDirectory(rootPath);
      if (!mounted) return;
      if (paths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noCompatibleBookFound)),
        );
        return;
      }
      final library = context.read<LibraryProvider>();
      final books =
          await DeviceScanResultsScreen.describe(paths, library.books);
      if (!mounted) return;
      final selectedPaths = await Navigator.of(context).push<List<String>>(
        MaterialPageRoute(
          builder: (_) => DeviceScanResultsScreen(
            books: books,
            rootPath: rootPath,
          ),
        ),
      );
      if (selectedPaths == null || selectedPaths.isEmpty || !mounted) return;
      await _importPaths(selectedPaths);
    } catch (error) {
      _showImportError(error);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _importPaths(List<String> paths) async {
    final result =
        await context.read<LibraryProvider>().importLocalFiles(paths);
    if (!mounted) return;
    final skipped =
        result.skipped == 0 ? '' : l10n.alreadyPresentOrSkipped(result.skipped);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.booksAddedCount(result.imported, skipped)),
      ),
    );
  }

  void _showImportError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.importFailed(error))),
    );
  }

  /// Desktop: pick one or more book files and add them to the library.
  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['cbz', 'cbr', 'zip', 'pdf', 'epub'],
    );
    final paths =
        result?.files.map((file) => file.path).whereType<String>().toList() ??
            const <String>[];
    if (paths.isEmpty || !mounted) return;
    setState(() => _importing = true);
    try {
      await _importPaths(paths);
    } catch (error) {
      _showImportError(error);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Desktop: choose a folder, then review the books found inside.
  Future<void> _pickFolder() async {
    final directory = await FilePicker.getDirectoryPath();
    if (directory == null || !mounted) return;
    await _scanAndReview(directory);
  }

  Future<void> _completeStorageAccessRequest() async {
    if (!mounted) return;
    if (await DeviceStorageAccessService.hasAllFilesAccess()) {
      await _scanDeviceStorage();
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.permissionNotGranted),
        ),
      );
    }
  }

  Future<bool> _showStorageAccessExplanation() async {
    final granted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scanPhoneTitle),
        content: Text(
          l10n.scanPhoneBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    return granted ?? false;
  }

  void _openReader(BookItem book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => buildSyncedReaderScreen(book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final localBooks = library.books
        .where((book) => book.serverId == null)
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    final theme = Theme.of(context);

    if (DesktopLayout.isWide(context)) {
      return _buildDesktop(localBooks, theme);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceFiles)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_copy_rounded,
                    size: 38, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  l10n.addComicsFromDevice,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.addComicsFromDeviceBody,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _importing ? null : _scanDeviceStorage,
                  icon: _importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search_rounded),
                  label: Text(_importing ? l10n.scanningFiles : l10n.scanPhone),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.addedFilesCount(localBooks.length),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (localBooks.isEmpty)
            ListTile(
              leading: Icon(Icons.folder_open_outlined),
              title: Text(l10n.noFileAdded),
              subtitle: Text(l10n.scanPhoneToFindBooks),
            )
          else
            for (final book in localBooks)
              Card(
                child: ListTile(
                  leading: Icon(_iconFor(book.format)),
                  title: Text(book.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(l10n.formatPageProgress(book.formatString,
                      book.currentPage + 1, book.totalPages)),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => _openReader(book),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDesktop(List<BookItem> localBooks, ThemeData theme) {
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    Widget headerCell(String text, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(text, style: muted),
        );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: DesktopLayout.contentPadding, vertical: 28),
        children: [
          DesktopContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.computerFiles,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _importing ? null : _pickFolder,
                      icon: const Icon(Icons.manage_search_rounded, size: 18),
                      label: Text(l10n.scanFolder),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _importing ? null : _pickFiles,
                      icon: _importing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                          _importing ? l10n.scanningFiles : l10n.openFiles),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withAlpha(90),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.folder_copy_rounded,
                            color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(l10n.addComicsFromComputerBody,
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.addedFilesCount(localBooks.length),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (localBooks.isEmpty)
                  Text(l10n.noFileAdded, style: theme.textTheme.bodyMedium)
                else
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          child: Row(
                            children: [
                              headerCell(l10n.columnTitle, flex: 5),
                              headerCell(l10n.columnFormat),
                              headerCell(l10n.columnSize),
                              headerCell(l10n.progress, flex: 2),
                              headerCell(l10n.columnAdded),
                              const SizedBox(width: 64),
                            ],
                          ),
                        ),
                        for (final book in localBooks)
                          _buildDesktopRow(book, theme),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(BookItem book, ThemeData theme) {
    final scheme = theme.colorScheme;
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final cover = book.coverPath;
    return InkWell(
      onTap: () => _openReader(book),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 30,
                      height: 42,
                      child: cover != null && File(cover).existsSync()
                          ? Image.file(File(cover),
                              fit: BoxFit.cover, cacheWidth: 90)
                          : ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(_iconFor(book.format), size: 16),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(book.formatString,
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer)),
                ),
              ),
            ),
            Expanded(
                child:
                    Text(FormatUtils.formatBytes(book.fileSize), style: muted)),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: book.progress,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    child: Text('${(book.progress * 100).round()} %',
                        style: muted),
                  ),
                ],
              ),
            ),
            Expanded(
                child: Text(FormatUtils.formatRelativeDate(book.addedDate),
                    style: muted)),
            SizedBox(
              width: 64,
              child: TextButton(
                onPressed: () => _openReader(book),
                child: Text(l10n.read),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(BookFormat format) => switch (format) {
        BookFormat.pdf => Icons.picture_as_pdf_rounded,
        BookFormat.epub => Icons.menu_book_rounded,
        _ => Icons.auto_stories_rounded,
      };
}
