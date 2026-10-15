import 'package:dummy_phone/phone/ride_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a ride request reaches a driver and a receipt', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: RideApp(branded: false)));
    await tester.pump();

    expect(find.text('Zippyride'), findsWidgets);
    expect(find.text('Uber'), findsNothing);
    expect(find.text('City'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('ride-request'))).onPressed, isNull);

    await tester.tap(find.text('Airport'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ride-pay')));
    await tester.pump();
    expect(find.text('Mastercard •••• 1881'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride-request')));
    await tester.pump();
    expect(find.text('Maya Ortiz'), findsOneWidget);
    expect(find.text('7KXP214'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride-start')));
    await tester.pump();
    expect(find.text('Heading to Airport'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride-end')));
    await tester.pump();
    expect(find.text('Trip complete'), findsOneWidget);
    expect(find.textContaining('\$12.40'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ride-done')));
    await tester.pump();
    expect(find.text('Request City'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('branded rides use the Uber names', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: RideApp(branded: true)));
    await tester.pump();
    expect(find.text('Uber'), findsWidgets);
    expect(find.text('UberX'), findsOneWidget);
    expect(find.text('Zippyride'), findsNothing);
  });

  testWidgets('a rider can cancel before the trip starts', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: RideApp(branded: true)));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('ride-destination')), 'City Hall');
    await tester.pump();
    await tester.tap(find.byKey(const Key('ride-option-2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ride-request')));
    await tester.pump();
    expect(find.textContaining('UberXL'), findsWidgets);
    await tester.tap(find.byKey(const Key('ride-cancel')));
    await tester.pump();
    expect(find.text('Maya Ortiz'), findsNothing);
    expect(find.text('Request UberXL'), findsOneWidget);
  });
}
