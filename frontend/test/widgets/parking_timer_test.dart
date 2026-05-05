import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingapp/widgets/parking_timer.dart';

void main() {
  Future<void> pumpTimerWidget(
    WidgetTester tester, {
    VoidCallback? onSessionEnd,
    void Function(Duration)? onExtend,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingTimer(
            onSessionEnd: onSessionEnd,
            onExtend: onExtend,
          ),
        ),
      ),
    );
  }

  testWidgets('shows initial inactive state', (WidgetTester tester) async {
    await pumpTimerWidget(tester);

    expect(find.text('Parking Session'), findsOneWidget);
    expect(find.text('Session Ended'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Start New Session'), findsOneWidget);
    expect(find.text('Stop Stay'), findsNothing);
  });

  testWidgets('starts session and extends by 30 minutes', (WidgetTester tester) async {
    Duration? extendedBy;

    await pumpTimerWidget(
      tester,
      onExtend: (duration) => extendedBy = duration,
    );

    await tester.tap(find.text('Start New Session'));
    await tester.pumpAndSettle();

    expect(find.text('Active Parking Session'), findsOneWidget);
    expect(find.text('Add Time to Start'), findsOneWidget);
    expect(find.text('+30 mins'), findsOneWidget);
    expect(find.text('+60 mins'), findsOneWidget);
    expect(find.text('Stop Stay'), findsOneWidget);

    await tester.tap(find.text('+30 mins'));
    await tester.pump();

    expect(extendedBy, const Duration(minutes: 30));
    expect(find.text('Time Remaining'), findsOneWidget);
    expect(find.text('00:30:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:29:59'), findsOneWidget);
  });

  testWidgets('stops session after confirmation and calls callback', (
    WidgetTester tester,
  ) async {
    var endedCount = 0;

    await pumpTimerWidget(
      tester,
      onSessionEnd: () => endedCount++,
    );

    await tester.tap(find.text('Start New Session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+30 mins'));
    await tester.pump();

    await tester.tap(find.text('Stop Stay'));
    await tester.pumpAndSettle();

    expect(find.text('End Session?'), findsOneWidget);
    expect(find.text('End Session'), findsOneWidget);

    await tester.tap(find.text('End Session'));
    await tester.pumpAndSettle();

    expect(endedCount, 1);
    expect(find.text('Start New Session'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
  });
}
