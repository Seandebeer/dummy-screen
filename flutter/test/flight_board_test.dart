import 'package:dummy_phone/models.dart';
import 'package:dummy_phone/phone/flight_board.dart';
import 'package:dummy_phone/phone/transport.dart';
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

  test('editing a flight time keeps the board in time order', () {
    final rows = [...kFlightBoardA];
    final first = flightCells(rows.first);
    first[0] = '14:30';
    rows[0] = flightRow(first);
    final ordered = orderedFlightBoard(rows, 0);
    expect(flightCells(ordered[8]).first, '14:23');
    expect(flightCells(ordered[9]).first, '14:30');
    expect(flightCells(ordered[10]).first, '14:50');
    expect(flightCells(ordered.first).first, '12:45');
  });

  testWidgets('the heading sits in a tall band and the rows stay short', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'flight-2',
      name: 'Gate board',
      projectId: 'sandbox',
      kind: 'flight',
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FlightBoard(store: store, device: device))),
    );
    await tester.pump();
    final heading = tester.getRect(find.text('Departures'));
    final board = tester.getSize(find.byKey(const Key('flight-board')));
    final last = tester.getRect(find.text('OSLO'));
    expect(heading.center.dx, greaterThan(300));
    expect(last.bottom, greaterThan(board.height - 24));
    expect(find.text('PC 593420'), findsOneWidget);
    expect(find.text('Skyline'), findsWidgets);
    expect(find.text('Alitalia'), findsNothing);
    expect(find.text('DELAYED'), findsWidgets);
    expect(find.text('C14'), findsOneWidget);
    final delayed = tester.widget<Text>(find.text('DELAYED').first);
    final cancelled = tester.widget<Text>(find.text('CANCELLED').first);
    expect(delayed.style?.color, const Color(0xFFFFD400));
    expect(cancelled.style?.color, const Color(0xFFFF3B30));
    final icon = tester.getRect(find.byIcon(Icons.flight_takeoff));
    expect(heading.left, greaterThan(icon.right));
    expect(heading.left - icon.right, lessThan(24));
  });

  testWidgets('branded flights keep the real airline names', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'flight-brand',
      name: 'Gate board',
      projectId: 'sandbox',
      kind: 'flight',
      os: const OsSettings(branded: true),
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FlightBoard(store: store, device: device))),
    );
    await tester.pump();
    expect(find.text('Alitalia'), findsWidgets);
    expect(find.text('SQ 593420'), findsOneWidget);
    expect(find.text('Skyline'), findsNothing);
  });

  testWidgets('a station board uses train words and a train mark', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final store = StageStore.demo();
    addTearDown(store.dispose);
    final device = PropDevice(
      id: 'train-1',
      name: 'Platform board',
      projectId: 'sandbox',
      kind: 'flight',
      os: applyTransport(const OsSettings(), 'train'),
    );
    store.upsertDevice(device);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FlightBoard(store: store, device: device))),
    );
    await tester.pump();
    expect(find.text('Departures'), findsOneWidget);
    expect(find.text('LONDON EUSTON'), findsOneWidget);
    expect(find.text('PLATFORM'), findsOneWidget);
    expect(find.text('National Rail'), findsWidgets);
    expect(find.text('Amtrak'), findsNothing);
    expect(find.byIcon(Icons.train), findsOneWidget);
    expect(find.text('CAPE TOWN'), findsNothing);
  });

  test('each place keeps eighteen rows and its own words', () {
    for (final mode in ['flight', 'train', 'bus', 'ferry']) {
      expect(transportBoard(mode, second: false), hasLength(18), reason: mode);
      expect(transportBoard(mode, second: true), hasLength(18), reason: mode);
      for (final row in transportBoard(mode, second: false)) {
        expect(flightCells(row), hasLength(7));
      }
    }
    expect(transportColumns('bus', 'departures')[4], 'BAY');
    expect(transportColumns('ferry', 'arrivals')[1], 'ORIGIN');
    expect(transportHeading('ferry', 'departures'), 'Sailings');
    expect(genericCarrier('Greyhound', 'bus')?.$2, 'CL');
    final shown = displayTransport(
      flightCells(kFlightBoardA[5]),
      5,
      mode: 'flight',
      branded: false,
    );
    expect(shown[2], 'Horizon');
    expect(shown[3], startsWith('HZ '));
  });
}
