import 'package:dummy_phone/vfx/colour_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom colour is an eyedropper on a spectrum, with hex as an option', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpectrumColourPicker(
            label: 'Custom colour',
            onPick: (hex) => picked = hex,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.colorize), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Custom colour'));
    await tester.pump();
    expect(find.byKey(const Key('colour-spectrum')), findsOneWidget);
    expect(find.byKey(const Key('colour-eyedropper')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const Key('colour-spectrum')));
    await tester.pump();
    expect(
      picked,
      colourFromSpectrum(hue: 0, saturation: 0.5, value: 0.5),
    );

    await tester.tap(find.byKey(const Key('colour-hex-option')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('colour-hex-field')), '112233');
    await tester.tap(find.byKey(const Key('colour-hex-use')));
    await tester.pump();
    expect(picked, '#112233');
  });
}
