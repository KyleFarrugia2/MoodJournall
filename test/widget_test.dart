import 'package:flutter_test/flutter_test.dart';
import 'package:homeassignment/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('MoodJournal'), findsOneWidget);
  });
}
