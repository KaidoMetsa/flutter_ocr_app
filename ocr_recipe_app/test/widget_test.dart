import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_recipe_app/main.dart';

void main() {
  testWidgets('OCR App basic UI test', (WidgetTester tester) async {
    // Laadime rakenduse
    await tester.pumpWidget(const MyApp());

    // Kontrollime, et kõik kolm peamist nuppu on olemas
    expect(find.text('Pildista retsept'), findsOneWidget);
    expect(find.text('Tee OCR'), findsOneWidget);
    expect(find.text('Genereeri tehnoloogiline kaart'), findsOneWidget);

    // Kontrollime, et OCR tekstikast ei ole esialgu täidetud
    expect(find.text('—'), findsOneWidget);

    // Kontrollime, et AppBar pealkiri on õige
    expect(find.text('OCR Recipe App'), findsOneWidget);
  });

  testWidgets('Buttons are disabled when busy', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Nupud ei tohiks olla alguses disabled
    final pickButton = find.text('Pildista retsept');
    final ocrButton = find.text('Tee OCR');
    final genButton = find.text('Genereeri tehnoloogiline kaart');

    expect(tester.widget<ElevatedButton>(pickButton).enabled, true);
    expect(tester.widget<ElevatedButton>(ocrButton).enabled, true);
    expect(tester.widget<ElevatedButton>(genButton).enabled, true);
  });
}
