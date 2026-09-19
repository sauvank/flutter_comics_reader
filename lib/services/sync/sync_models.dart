enum SyncStatus { offline, signedOut, idle, syncing, conflict, error }

/// The version selected by the user when the same data was changed locally and
/// remotely since the last successful synchronisation.
enum SyncConflictResolution { keepLocal, keepRemote }

class SyncConflict {
  const SyncConflict({
    required this.documentId,
    required this.label,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
  });

  final String documentId;
  final String label;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
}
