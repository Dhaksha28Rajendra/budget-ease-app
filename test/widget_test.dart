import 'package:flutter_test/flutter_test.dart';
import 'package:budget_ease/main.dart';

void main() {
  testWidgets('Budget Ease app loads correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const BudgetEaseApp());

    // Verify Login screen text appears
    expect(find.text('Budget Ease'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
