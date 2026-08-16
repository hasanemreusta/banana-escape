import 'package:banana_escape/app/banana_escape_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash screen renders app title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BananaEscapeApp());
    await tester.pump();

    expect(find.text('Banana Escape'), findsOneWidget);
  });
}
