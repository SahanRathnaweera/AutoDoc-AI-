import 'package:flutter_test/flutter_test.dart';

import 'package:autodoc_ai/main.dart';

void main() {
  testWidgets('renders the AutoDoc AI base setup screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AutoDocApp());

    expect(find.text('AutoDoc AI Base Setup Ready'), findsOneWidget);
  });
}
