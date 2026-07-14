import 'package:flutter_test/flutter_test.dart';
import 'package:unigest_app/app.dart';

void main() {
  testWidgets('MyApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('UniGest'), findsOneWidget);
  });
}
