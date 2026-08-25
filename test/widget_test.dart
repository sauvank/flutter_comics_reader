import 'package:flutter_test/flutter_test.dart';
import 'package:comic_reader_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ComicStreamApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ComicStreamApp());
    await tester.pumpAndSettle();

    expect(find.text('Ma Bibliothèque'), findsOneWidget);
  });
}
