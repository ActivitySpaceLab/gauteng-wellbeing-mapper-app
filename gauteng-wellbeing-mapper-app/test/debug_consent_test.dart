import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/ui/consent_form_screen.dart';

void main() {
  testWidgets('Debug consent form structure', (WidgetTester tester) async {
    // Set a larger surface size to accommodate the long consent form
    tester.view.physicalSize = Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    
    // Build the consent form for Gauteng research site
    await tester.pumpWidget(
      MaterialApp(
        home: ConsentFormScreen(
          participantCode: 'TEST001',
          researchSite: 'gauteng',
          isTestingMode: true,
        ),
      ),
    );

    // Wait for the widget to build
    await tester.pumpAndSettle();

    // Debug: Print all widgets to see structure
    print('=== INITIAL WIDGET TREE ===');
    print(tester.allWidgets.where((w) => w.runtimeType.toString().contains('Text')).map((w) => w.toString()).join('\n'));

    // Scroll to find the Continue button and tap it
    await tester.scrollUntilVisible(
      find.text('Continue to Consent Form'),
      500.0, // scroll distance
    );
    await tester.tap(find.text('Continue to Consent Form'));
    await tester.pumpAndSettle();

    // Debug: Print widget tree after navigating to consent form
    print('=== AFTER CONTINUE BUTTON ===');
    
    // Look for all Text widgets containing "participate"
    final participateTexts = find.textContaining('participate');
    print('Found ${participateTexts.evaluate().length} widgets containing "participate":');
    for (final element in participateTexts.evaluate()) {
      final widget = element.widget as Text;
      print('  - "${widget.data}"');
    }
    
    // Look for all Checkbox widgets
    final checkboxes = find.byType(Checkbox);
    print('Found ${checkboxes.evaluate().length} Checkbox widgets');
    
    // Look for all widgets containing consent texts
    final consentTexts = [
      'to participate in this study',
      'for my personal data to be processed',
      'to being asked about my health',
    ];
    
    for (String text in consentTexts) {
      final textWidgets = find.textContaining(text);
      final count = textWidgets.evaluate().length;
      print('Text "$text": found $count widgets');
      if (count > 0) {
        // Ensure the target is visible in any scrollable before tapping to avoid off-screen warnings
        await tester.ensureVisible(textWidgets.first);
        await tester.pumpAndSettle();
        print('Tapping consent text: $text');
        await tester.tap(textWidgets.first, warnIfMissed: false);
        await tester.pump();
        print('After tapping and pumping');
      }
    }
    
    // Check button state after tapping some consents
    await tester.pumpAndSettle();
    final submitButton = find.byType(ElevatedButton);
    if (submitButton.evaluate().isNotEmpty) {
      final button = tester.widget(submitButton) as ElevatedButton;
      print('Submit button enabled: ${button.onPressed != null}');
    }
  });
}
