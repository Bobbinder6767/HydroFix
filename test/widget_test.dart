import 'package:flutter_test/flutter_test.dart';
import 'package:hydrofix/app.dart';

void main() {
  testWidgets('Hydrofix welcome screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const HydrofixApp());

    expect(find.text('Welcome to Hydrofix'), findsOneWidget);
  });
}