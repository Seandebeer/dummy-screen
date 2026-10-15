import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/flight_board.dart';
import 'package:dummy_phone/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new camera wall starts with six cameras', () {
    expect(const OsSettings().cctvCount, 6);
    expect(OsSettings.fromJson(const {}).cctvCount, 6);
    expect(OsSettings.fromJson(const {'cctvCount': 4}).cctvCount, 4);
  });

  test('flight boards survive a save', () {
    const os = OsSettings(flightHeading: 'arrivals', flightFlip: true, flightFlipSeconds: 5);
    final back = OsSettings.fromJson(os.toJson());
    expect(back.flightHeading, 'arrivals');
    expect(back.flightFlip, isTrue);
    expect(back.flightFlipSeconds, 5);
    expect(back.flightA.first, contains('CAPE TOWN'));
    expect(back, os);
  });

  testWidgets('the board shows the reference flights and edits a cell', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'flight-1',
      name: 'Gate board',
      projectId: 'sandbox',
      kind: 'flight',
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlightBoard(store: store, device: device)),
      ),
    );
    await tester.pump();

    expect(find.text('Departures'), findsOneWidget);
    expect(find.text('CAPE TOWN'), findsOneWidget);
    expect(find.text('CANCELLED'), findsWidgets);
    expect(find.text('Thu 25 November 2010'), findsOneWidget);

    await tester.tap(find.byKey(const Key('flight-cell-0-0-1')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('flight-cell-0-0-1')), 'DURBAN');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(store.deviceById(device.id)?.os.flightA.first, contains('DURBAN'));
  });
}
