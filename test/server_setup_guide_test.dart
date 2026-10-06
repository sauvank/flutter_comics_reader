import 'package:comic_reader_app/widgets/server_setup_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Server setup guide explains the steps and wires its buttons',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var added = 0;
    var imported = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ServerSetupGuide(
          onAddServer: () => added++,
          onImportConfiguration: () => imported++,
        ),
      ),
    ));

    expect(find.text('Partagez votre dossier de BD'), findsOneWidget);

    await tester.tap(find.text('Ajouter un serveur'));
    await tester.scrollUntilVisible(find.text('WebDAV'), 300);
    await tester.tap(find.text('WebDAV'));
    await tester.pumpAndSettle();
    expect(find.text('5005 (Synology), 80 ou 443'), findsOneWidget);

    await tester.scrollUntilVisible(
        find.text('Importer une configuration existante'), 300);
    await tester.tap(find.text('Importer une configuration existante'));
    expect((added, imported), (1, 1));
  });
}
