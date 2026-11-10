import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/inspection/presentation/pages/inspection_pages.dart';

void main() {
  testWidgets('can create a clearly labeled simulated report without media', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InspectionReportPage()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Toyota');
    await tester.enterText(fields.at(1), 'Corolla');
    await tester.enterText(fields.at(2), '2020');
    await tester.enterText(fields.at(3), '45000');
    await tester.enterText(fields.at(4), 'DEMO-123');
    await tester.enterText(fields.at(5), '25000');

    final generateDemo = find.text('Generate simulated demo report');
    await tester.scrollUntilVisible(
      generateDemo,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(generateDemo);
    await tester.pumpAndSettle();

    expect(find.text('Simulated placeholder output'), findsOneWidget);
    expect(find.textContaining('SIMULATED:'), findsWidgets);
    expect(
      find.textContaining('No vehicle photos or engine audio were analyzed.'),
      findsOneWidget,
    );
    expect(find.text('Download / share PDF report'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.textContaining('SIMULATED DEMO REPORT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
