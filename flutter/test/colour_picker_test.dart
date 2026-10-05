import 'package:dummy_phone/vfx/colour_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a custom colour is chosen from the palette, with hex as an option', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaletteColourPicker(
            label: 'Custom colour',
            onPick: (hex) => picked = hex,
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Custom colour'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('colour-hex-option')), findsOneWidget);

    final first = paletteColourHexes().first;
    await tester.tap(find.byKey(Key('swatch-$first')));
    await tester.pump();
    expect(picked, first);

    await tester.tap(find.byKey(const Key('colour-hex-option')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('colour-hex-field')), '112233');
    await tester.tap(find.byKey(const Key('colour-hex-use')));
    await tester.pump();
    expect(picked, '#112233');
  });
}
