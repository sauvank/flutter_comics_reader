import 'package:comic_reader_app/screens/account/account_screen.dart';
import 'package:comic_reader_app/services/sync/firebase_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Account screen remains usable without Firebase configuration',
      (tester) async {
    FirebaseBootstrap.isAvailable = false;

    await tester.pumpWidget(const MaterialApp(home: AccountScreen()));

    expect(find.text('Compte et synchronisation'), findsOneWidget);
    expect(
      find.textContaining('configuration du projet Firebase'),
      findsOneWidget,
    );
  });
}
