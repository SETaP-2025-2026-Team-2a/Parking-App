import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/pages/settings_page.dart';
import 'package:parkingapp/utils/theme_manager.dart';

void main() {
  setUp(() {
    ThemeManager().setDarkMode(false);
  });

  Future<void> pumpSettingsPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsTabContent(),
      ),
    );
  }

  Finder switchForTitle(String title) {
    final tile = find.widgetWithText(SwitchListTile, title);
    return find.descendant(of: tile, matching: find.byType(Switch));
  }

  testWidgets('renders settings sections and default switch values', (
    WidgetTester tester,
  ) async {
    await pumpSettingsPage(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);

    expect(tester.widget<Switch>(switchForTitle('Push Notifications')).value, isTrue);
    expect(tester.widget<Switch>(switchForTitle('Parking Reminders')).value, isFalse);
    expect(tester.widget<Switch>(switchForTitle('Dark Mode')).value, isFalse);
    expect(tester.widget<Switch>(switchForTitle('Location Services')).value, isTrue);
  });

  testWidgets('toggles switches when tapped', (WidgetTester tester) async {
    await pumpSettingsPage(tester);

    await tester.tap(switchForTitle('Push Notifications'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchForTitle('Push Notifications')).value, isFalse);

    await tester.tap(switchForTitle('Parking Reminders'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchForTitle('Parking Reminders')).value, isTrue);

    await tester.tap(switchForTitle('Location Services'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchForTitle('Location Services')).value, isFalse);

    await tester.tap(switchForTitle('Dark Mode'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchForTitle('Dark Mode')).value, isTrue);
  });

  testWidgets('shows support snackbars and about dialog', (
    WidgetTester tester,
  ) async {
    await pumpSettingsPage(tester);

    await tester.tap(find.text('Help & Support'));
    await tester.pump();
    expect(find.text('Help & Support clicked'), findsOneWidget);

    final privacyPolicyTile = find.widgetWithText(ListTile, 'Privacy Policy');
    await tester.scrollUntilVisible(
      privacyPolicyTile,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(privacyPolicyTile);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    final aboutTile = find.widgetWithText(ListTile, 'About');
    await tester.scrollUntilVisible(
      aboutTile,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(aboutTile);
    await tester.pumpAndSettle();
    expect(find.text('About Parking App'), findsOneWidget);
    expect(find.text('Version: 1.0.0'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('About Parking App'), findsNothing);
  });

  testWidgets('shows logout dialog and success snackbar', (
    WidgetTester tester,
  ) async {
    await pumpSettingsPage(tester);

    final logoutButton = find.widgetWithText(ElevatedButton, 'Logout');
    await tester.scrollUntilVisible(
      logoutButton,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(logoutButton);
    await tester.pump();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to logout?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Logged out successfully'), findsOneWidget);
  });
}
