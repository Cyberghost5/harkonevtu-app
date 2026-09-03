import 'package:flutter_test/flutter_test.dart';
import 'package:nmillenium/main.dart';

void main() {
  testWidgets('App initializes successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HarkoneVtuApp());
    expect(find.byType(HarkoneVtuApp), findsOneWidget);
  });
}
