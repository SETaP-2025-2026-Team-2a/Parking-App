import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/pages/login_page.dart';

void main() {
  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );
  }

  Finder usernameField() {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'Username',
    );
  }

  Finder passwordField() {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == 'Password',
    );
  }

  testWidgets('renders login page with all expected fields and buttons', (
    WidgetTester tester,
  ) async {
    await pumpLoginPage(tester);

    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(usernameField(), findsOneWidget);
    expect(passwordField(), findsOneWidget);
  });

  testWidgets('username field accepts text input', (WidgetTester tester) async {
    await pumpLoginPage(tester);

    final username = usernameField();
    expect(username, findsOneWidget);

    await tester.enterText(username, 'testuser');
    await tester.pump();

    expect(find.text('testuser'), findsOneWidget);
  });

  testWidgets('password field is obscured and present', (WidgetTester tester) async {
    await pumpLoginPage(tester);

    final password = passwordField();
    expect(password, findsOneWidget);

    final passwordWidget = tester.widget<TextField>(password);
    expect(passwordWidget.obscureText, isTrue);
  });

  testWidgets('login button is enabled and tappable', (WidgetTester tester) async {
    await pumpLoginPage(tester);

    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginButton, findsOneWidget);

    final buttonWidget = tester.widget<ElevatedButton>(loginButton);
    expect(buttonWidget.onPressed, isNotNull);

    await tester.tap(loginButton);
    await tester.pump();
  });
}