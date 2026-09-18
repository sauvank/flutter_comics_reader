enum SyncStatus { offline, signedOut, idle, syncing, conflict, error }

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
