import 'package:flutter_test/flutter_test.dart';
import 'package:compass_app/main.dart';

void main() {
  testWidgets('App shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const CompassApp());
    expect(find.text('Modern Compass'), findsOneWidget);
  });
}
