import 'package:comic_reader_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('large windows use a side menu instead of the bottom bar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComicStreamApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Bibliothèque'), findsWidgets);

    await tester.tap(find.text('Serveurs'));
    await tester.pumpAndSettle();
    expect(find.text('Mes Serveurs'), findsOneWidget);
  });
}
