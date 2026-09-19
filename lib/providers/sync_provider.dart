import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sync/firebase_bootstrap.dart';
import '../services/sync/sync_models.dart';
import '../services/sync/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  SyncProvider({SyncService? service}) : _service = service ?? SyncService();
  final SyncService _service;
  SyncStatus status = SyncStatus.signedOut;
  List<SyncConflict> conflicts = [];
  StreamSubscription? _authSub;
  StreamSubscription? _changesSub;
  Timer? _debounce;

  void start() {
    if (!FirebaseBootstrap.isAvailable) return;
    _authSub = _service.authChanges.listen((user) {
      status = user == null ? SyncStatus.signedOut : SyncStatus.idle;
      notifyListeners();
      if (user != null) schedule();
    });
    _changesSub = DatabaseService().syncChanges.listen((_) => schedule());
  }

  void schedule() {
    if (_service.user == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), syncNow);
  }

  Future<void> syncNow() async {
    if (_service.user == null || status == SyncStatus.syncing) return;
    status = SyncStatus.syncing;
    notifyListeners();
    try {
      conflicts = await _service.syncNow();
      status = conflicts.isEmpty ? SyncStatus.idle : SyncStatus.conflict;
    } catch (_) {
      status = SyncStatus.error;
    }
    notifyListeners();
  }

  /// Clears conflicts already resolved from the manual account screen. The
  /// automatic and manual paths share the same data, but not the same service
  /// instance, so the automatic status must not keep showing a stale prompt.
  void clearResolvedConflicts() {
    if (conflicts.isEmpty && status != SyncStatus.conflict) return;
    conflicts = [];
    if (status == SyncStatus.conflict) status = SyncStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _changesSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
