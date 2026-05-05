import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/pages/history_page.dart';
import 'package:parkingapp/user_addition/user_model.dart';

void main() {
  group('History Page Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: child,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
      );
    }

    final testSession = AuthSession(userId: 1, name: 'You', lastname: '', email: 'you@parking.test', accessToken: '');

    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      expect(find.text('Parking Reviews'), findsOneWidget);
      expect(find.text('All Reviews'), findsOneWidget);
      // 'User Reviews' header removed in UI; ensure main reviews header exists instead
    });

    testWidgets('initial rating is 5 stars', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      expect(find.text('Rate: 5 / 5'), findsOneWidget);
    });

    testWidgets('star rating changes on tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final starIcons = find.byIcon(Icons.star);
      await tester.tap(starIcons.first);
      await tester.pump();
      expect(find.text('Rate: 1 / 5'), findsOneWidget);
    });

    testWidgets('can set 3 star rating', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final starIcons = find.byIcon(Icons.star);
      await tester.tap(starIcons.at(2));
      await tester.pump();
      expect(find.text('Rate: 3 / 5'), findsOneWidget);
    });

    testWidgets('text field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'Great spot!');
      expect(find.text('Great spot!'), findsOneWidget);
    });

    testWidgets('submit button shows error when empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Please enter a comment'), findsOneWidget);
    });

    testWidgets('submits review successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'Excellent location!');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Review submitted!'), findsOneWidget);
    });

    testWidgets('clears comment after submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'Test');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Test'), findsNothing);
    });

    testWidgets('resets rating after submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final starIcons = find.byIcon(Icons.star);
      await tester.tap(starIcons.at(2));
      await tester.pump();
      expect(find.text('Rate: 3 / 5'), findsOneWidget);

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'Good');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Rate: 5 / 5'), findsOneWidget);
    });

    testWidgets('displays past reviews', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(
        find.text(
          'Great location! Easy to find and very secure. Highly recommended.',
        ),
        findsOneWidget,
      );
      expect(find.text('Mike Chen'), findsOneWidget);
    });

    testWidgets('shows submitted review as You', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'New review');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('has all 5 interactive stars', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      for (int i = 1; i <= 5; i++) {
        final starIcons = find.byIcon(Icons.star);
        await tester.tap(starIcons.at(i - 1));
        await tester.pump();
        expect(find.text('Rate: $i / 5'), findsOneWidget);
      }
    });

    testWidgets('text field supports multiple lines', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, equals(3));
    });

    testWidgets('displays all past reviews', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(find.text('Sarah Williams'), findsOneWidget);
      expect(find.text('Mike Chen'), findsOneWidget);
      expect(find.text('Emma Green'), findsOneWidget);
    });

    testWidgets('submit button exists', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('has hint text in comment field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(HistoryTabContent(session: testSession)));
      expect(find.text('Share your feedback...'), findsOneWidget);
    });
  });
}
