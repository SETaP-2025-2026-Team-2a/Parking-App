import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/pages/profile_page.dart';

void main() {
  Future<void> pumpProfilePage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileTabContent()),
    );
  }

  Finder infoTile(String title) {
    return find.widgetWithText(ListTile, title);
  }

  Finder sectionHeader(String title) {
    return find.text(title);
  }

  testWidgets('renders profile page sections and initial content', (
    WidgetTester tester,
  ) async {
    await pumpProfilePage(tester);

    expect(sectionHeader('Profile'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john.doe@example.com'), findsOneWidget);
    expect(sectionHeader('Personal Information'), findsOneWidget);
    expect(sectionHeader('Vehicle Garage'), findsOneWidget);
    expect(sectionHeader('Payment Methods'), findsOneWidget);

    expect(infoTile('Name'), findsOneWidget);
    expect(infoTile('Email'), findsOneWidget);
    expect(infoTile('Password'), findsOneWidget);
    expect(find.text('My Car'), findsOneWidget);
    expect(find.text('Work Van'), findsOneWidget);
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('Mastercard •••• 8888'), findsOneWidget);
  });

  testWidgets('tapping avatar camera shows change profile picture snackbar', (
    WidgetTester tester,
  ) async {
    await pumpProfilePage(tester);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(find.text('Change profile picture'), findsOneWidget);
  });

  testWidgets('editing name updates the displayed profile name', (
    WidgetTester tester,
  ) async {
    await pumpProfilePage(tester);

    await tester.tap(infoTile('Name'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Name'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Jane Doe');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Name updated successfully'), findsOneWidget);
  });

  testWidgets('password dialog shows and handles save action when passwords match', (
    WidgetTester tester,
  ) async {
    await pumpProfilePage(tester);

    await tester.tap(infoTile('Password'));
    await tester.pumpAndSettle();

    expect(find.text('Change Password'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));

    await tester.enterText(fields.at(0), 'current123');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.enterText(fields.at(2), 'secret123');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Password changed successfully'), findsOneWidget);
  });

  testWidgets('adding a vehicle shows a new vehicle card', (WidgetTester tester) async {
    await pumpProfilePage(tester);

    final addButtons = find.byIcon(Icons.add);
    expect(addButtons, findsNWidgets(2));
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Add Vehicle'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nickname'), 'New Ride');
    await tester.enterText(find.widgetWithText(TextField, 'Number Plate (VRM)'), 'TEST 999');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New Ride'), findsOneWidget);
    expect(find.text('Vehicle added successfully'), findsOneWidget);
  });

  testWidgets('deleting a payment method removes it from the page', (
    WidgetTester tester,
  ) async {
    await pumpProfilePage(tester);

    final deleteButtons = find.byIcon(Icons.delete);
    expect(deleteButtons, findsWidgets);

    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Are you sure you want to delete'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Payment method deleted successfully'), findsOneWidget);
  });
}