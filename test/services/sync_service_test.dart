import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:comic_reader_app/services/sync/sync_service.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  AuthProvider? lastProvider;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    lastProvider = provider;
    return _FakeUserCredential();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('signInWithGoogle falls back safely when native GoogleSignIn is not available', () async {
    final fakeAuth = _FakeFirebaseAuth();
    final service = SyncService(
      auth: fakeAuth,
      googleSignIn: GoogleSignIn.instance,
    );

    await service.signInWithGoogle();

    expect(fakeAuth.lastProvider, isA<GoogleAuthProvider>());
  });
}
