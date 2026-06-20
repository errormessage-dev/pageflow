import 'package:flutter_test/flutter_test.dart';

import 'package:pageflow/main.dart';

void main() {
  testWidgets('Pageflow app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PageflowApp());

    // Verify that the app title is displayed
    expect(find.text('Pageflow'), findsOneWidget);
    
    // Verify that the "Open PDF" button is present
    expect(find.text('Open PDF'), findsOneWidget);
  });
} 