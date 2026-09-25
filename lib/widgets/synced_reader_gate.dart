import 'package:flutter/material.dart';

import '../models/book_item.dart';
import '../services/database_service.dart';
import '../services/sync/firebase_bootstrap.dart';
import '../services/sync/sync_models.dart';
import '../services/sync/sync_service.dart';

typedef SyncedReaderBuilder = Widget Function(BookItem book);

/// Resolves a book-scoped device sync before displaying a reader and checks
/// again when an already-open reader returns from the background.
class SyncedReaderGate extends StatefulWidget {
  const SyncedReaderGate({
    super.key,
    required this.book,
    required this.readerBuilder,
  });

  final BookItem book;
  final SyncedReaderBuilder readerBuilder;

  @override
  State<SyncedReaderGate> createState() => _SyncedReaderGateState();
}

class _SyncedReaderGateState extends State<SyncedReaderGate>
    with WidgetsBindingObserver {
  final SyncService _sync = SyncService();
  final DatabaseService _database = DatabaseService();
  late BookItem _book;
  bool _ready = false;
  bool _checking = false;
  int _readerGeneration = 0;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProgress());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ready) {
      _checkProgress();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _publishLatestPosition();
    }
  }

  Future<void> _publishLatestPosition() async {
    if (!FirebaseBootstrap.isAvailable) return;
    // Reader lifecycle callbacks queue their last position in a microtask.
    // Yield once, then wait for that write before starting the cloud sync.
    await Future<void>.delayed(Duration.zero);
    await _database.flushBookWrites();
    try {
      await _sync.syncNow();
    } catch (_) {
      // The normal automatic sync retries after the next local change.
    }
  }

  Future<void> _checkProgress() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      final latest = (await _database.getBooks())
              .where((book) => book.id == _book.id)
              .firstOrNull ??
          _book;
      BookSyncProposal? proposal;
      if (FirebaseBootstrap.isAvailable) {
        proposal = await _sync.bookProgressProposal(latest);
      }
      if (!mounted) return;

      if (proposal != null) {
        final choice = await _showProposal(proposal);
        if (!mounted) return;
        if (choice == BookProgressChoice.useRemote && _ready) {
          // Let the active reader persist its final local position before it
          // is replaced. The remote choice is applied only afterwards.
          setState(() => _ready = false);
          await WidgetsBinding.instance.endOfFrame;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
        await _sync.resolveBookProgress(proposal, choice);
      }

      final refreshed = (await _database.getBooks())
              .where((book) => book.id == _book.id)
              .firstOrNull ??
          latest;
      if (mounted) {
        setState(() {
          _book = refreshed;
          _readerGeneration++;
          _ready = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _ready = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Synchronisation de ce livre indisponible. Lecture locale conservée : $error'),
        ),
      );
    } finally {
      _checking = false;
    }
  }

  Future<BookProgressChoice> _showProposal(BookSyncProposal proposal) async {
    final choice = await showDialog<BookProgressChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Progression trouvée sur un autre appareil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '« ${proposal.remoteDeviceName} » possède une autre position pour ce livre.',
            ),
            const SizedBox(height: 16),
            _PositionLine(
              label: proposal.remoteDeviceName,
              page: proposal.remotePage,
              totalPages: proposal.remoteTotalPages,
              chapterProgress: proposal.remoteChapterProgress,
              updatedAt: proposal.remoteUpdatedAt,
              isEpub: proposal.isEpub,
            ),
            const SizedBox(height: 8),
            _PositionLine(
              label: 'Cet appareil',
              page: proposal.localPage,
              totalPages: proposal.localTotalPages,
              chapterProgress: proposal.localChapterProgress,
              updatedAt: proposal.localUpdatedAt,
              isEpub: proposal.isEpub,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(BookProgressChoice.ignore),
            child: const Text('Ignorer'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(BookProgressChoice.keepLocal),
            child: const Text('Conserver ici'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(BookProgressChoice.useRemote),
            child: Text('Continuer depuis ${proposal.remoteDeviceName}'),
          ),
        ],
      ),
    );
    return choice ?? BookProgressChoice.ignore;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return KeyedSubtree(
      key: ValueKey('${_book.id}:$_readerGeneration'),
      child: widget.readerBuilder(_book),
    );
  }
}

class _PositionLine extends StatelessWidget {
  const _PositionLine({
    required this.label,
    required this.page,
    required this.totalPages,
    required this.chapterProgress,
    required this.updatedAt,
    required this.isEpub,
  });

  final String label;
  final int page;
  final int totalPages;
  final double chapterProgress;
  final DateTime updatedAt;
  final bool isEpub;

  @override
  Widget build(BuildContext context) {
    final local = updatedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(local);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    final location = isEpub
        ? 'Chapitre ${page + 1}/$totalPages · ${(chapterProgress * 100).round()} %'
        : 'Page ${page + 1}/$totalPages';
    return Text('$label : $location\n$date à $time');
  }
}
