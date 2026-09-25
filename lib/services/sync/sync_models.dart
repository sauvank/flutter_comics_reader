enum SyncStatus { offline, signedOut, idle, syncing, conflict, error }

/// The version selected by the user when the same data was changed locally and
/// remotely since the last successful synchronisation.
enum SyncConflictResolution { keepLocal, keepRemote }

/// Choice made when the same book has a different reading position on another
/// installation.
enum BookProgressChoice { useRemote, keepLocal, ignore }

/// Outcome of renaming the local installation. The name is always persisted
/// locally first; a remote retry can happen during the next synchronization.
enum DeviceRenameResult { synced, savedLocally }

class SyncConflict {
  const SyncConflict({
    required this.documentId,
    required this.label,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    required this.localSummary,
    required this.remoteSummary,
  });

  final String documentId;
  final String label;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;

  /// Human-readable, non-sensitive details shown before replacing a version.
  final String localSummary;
  final String remoteSummary;
}

/// An encrypted point-in-time copy kept separately for one installation.
///
/// The label is an anonymous, locally generated alias: no device model, name,
/// or other identifying information is uploaded.
class SyncDeviceBackup {
  const SyncDeviceBackup({
    required this.id,
    required this.label,
    required this.isCurrentDevice,
    this.updatedAt,
  });

  final String id;
  final String label;
  final bool isCurrentDevice;
  final DateTime? updatedAt;
}

/// A device-specific reading position offered when a book is opened.
class BookSyncProposal {
  const BookSyncProposal({
    required this.bookId,
    required this.progressId,
    required this.remoteDeviceId,
    required this.remoteDeviceName,
    required this.localPage,
    required this.localTotalPages,
    required this.localChapterProgress,
    required this.localUpdatedAt,
    required this.remotePage,
    required this.remoteTotalPages,
    required this.remoteChapterProgress,
    required this.remoteUpdatedAt,
    required this.isEpub,
  });

  final String bookId;
  final String progressId;
  final String remoteDeviceId;
  final String remoteDeviceName;
  final int localPage;
  final int localTotalPages;
  final double localChapterProgress;
  final DateTime localUpdatedAt;
  final int remotePage;
  final int remoteTotalPages;
  final double remoteChapterProgress;
  final DateTime remoteUpdatedAt;
  final bool isEpub;
}
