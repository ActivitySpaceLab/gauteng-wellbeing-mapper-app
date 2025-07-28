import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wellbeing_mapper/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Configure screenshot directory based on device type
  String getScreenshotPath(String screenName) {
    final size = binding.window.physicalSize;
    final devicePixelRatio = binding.window.devicePixelRatio;
    final logicalSize = size / devicePixelRatio;
    
    String deviceType;
    if (logicalSize.shortestSide >= 600) {
      if (logicalSize.shortestSide >= 900) {
        deviceType = '10inch_tablet';
      } else {
        deviceType = '7inch_tablet';
      }
    } else {
      deviceType = 'phone';
    }
    
    return '${deviceType}_${screenName}';
  }
  
  // Helper to wait for app to be ready
  Future<void> waitForAppReady(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // Wait for MaterialApp to be ready
    expect(find.byType(MaterialApp), findsOneWidget);
  }
  
  // Helper to take screenshot with retry logic
  Future<void> takeScreenshotSafely(String screenName, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        await binding.takeScreenshot(getScreenshotPath(screenName));
        print('✅ Screenshot taken: ${getScreenshotPath(screenName)}');
        return;
      } catch (e) {
        print('⚠️  Screenshot attempt ${i + 1} failed: $e');
        if (i == retries - 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
  
  group('Wellbeing Mapper Screenshots', () {
    testWidgets('01 - App Launch and Participation Selection', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Take screenshot of the initial screen (participation selection)
      await takeScreenshotSafely('01_participation_selection');
      
      print('Screen size: ${tester.binding.window.physicalSize}');
      print('Device pixel ratio: ${tester.binding.window.devicePixelRatio}');
      print('Logical size: ${tester.binding.window.physicalSize / tester.binding.window.devicePixelRatio}');
    });

    testWidgets('02 - Private Mode Selection', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Find and tap private mode
      final privateMode = find.textContaining('Private').first;
      if (privateMode.evaluate().isNotEmpty) {
        await tester.tap(privateMode);
        await tester.pumpAndSettle();
        await takeScreenshotSafely('02_private_mode_main');
      } else {
        await takeScreenshotSafely('02_private_mode_fallback');
      }
    });

    testWidgets('03 - Research Participation - Barcelona', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to Barcelona research mode
      final barcelonaOption = find.textContaining('Barcelona');
      if (barcelonaOption.evaluate().isNotEmpty) {
        await tester.tap(barcelonaOption.first);
        await tester.pumpAndSettle();
        
        // Look for consent form or next step
        final continueButton = find.textContaining('Continue');
        final consentButton = find.textContaining('Consent');
        
        if (continueButton.evaluate().isNotEmpty) {
          await takeScreenshotSafely('03_barcelona_consent_step1');
          await tester.tap(continueButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('03_barcelona_consent_step2');
        } else if (consentButton.evaluate().isNotEmpty) {
          await takeScreenshotSafely('03_barcelona_consent_form');
        } else {
          await takeScreenshotSafely('03_barcelona_research_mode');
        }
      }
    });

    testWidgets('04 - Map Interface', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode first to access main app
      final privateMode = find.textContaining('Private');
      if (privateMode.evaluate().isNotEmpty) {
        await tester.tap(privateMode.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for map navigation elements
        final mapButton = find.textContaining('Map');
        final mapIcon = find.byIcon(Icons.map);
        
        if (mapButton.evaluate().isNotEmpty) {
          await tester.tap(mapButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          await takeScreenshotSafely('04_map_interface');
        } else if (mapIcon.evaluate().isNotEmpty) {
          await tester.tap(mapIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          await takeScreenshotSafely('04_map_via_icon');
        } else {
          // Check for bottom navigation
          final bottomNav = find.byType(BottomNavigationBar);
          if (bottomNav.evaluate().isNotEmpty) {
            await takeScreenshotSafely('04_main_app_with_navigation');
          } else {
            await takeScreenshotSafely('04_main_app_home');
          }
        }
      }
    });

    testWidgets('05 - Survey Interface', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode
      final privateMode = find.textContaining('Private');
      if (privateMode.evaluate().isNotEmpty) {
        await tester.tap(privateMode.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for survey-related elements
        final surveyButton = find.textContaining('Survey');
        final addButton = find.byIcon(Icons.add);
        final floatingActionButton = find.byType(FloatingActionButton);
        
        if (surveyButton.evaluate().isNotEmpty) {
          await tester.tap(surveyButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('05_survey_interface');
        } else if (addButton.evaluate().isNotEmpty) {
          await tester.tap(addButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('05_add_survey');
        } else if (floatingActionButton.evaluate().isNotEmpty) {
          await tester.tap(floatingActionButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('05_fab_survey');
        } else {
          await takeScreenshotSafely('05_main_screen_for_survey');
        }
      }
    });

    testWidgets('06 - Settings and Navigation', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode
      final privateMode = find.textContaining('Private');
      if (privateMode.evaluate().isNotEmpty) {
        await tester.tap(privateMode.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for settings or menu
        final settingsIcon = find.byIcon(Icons.settings);
        final menuIcon = find.byIcon(Icons.menu);
        final moreIcon = find.byIcon(Icons.more_vert);
        
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('06_settings_interface');
        } else if (menuIcon.evaluate().isNotEmpty) {
          await tester.tap(menuIcon.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('06_navigation_menu');
        } else if (moreIcon.evaluate().isNotEmpty) {
          await tester.tap(moreIcon.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('06_more_options_menu');
        } else {
          await takeScreenshotSafely('06_main_interface_overview');
        }
      }
    });
  });
      } else {
        // Look for radio buttons or other selection widgets
        final radioButtons = find.byType(Radio);
        if (radioButtons.evaluate().isNotEmpty) {
          await tester.tap(radioButtons.first);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('03_radio_selection');
        } else {
          await binding.takeScreenshot('03_current_state');
        }
      }
    });

    testWidgets('04 - Navigate to Barcelona Research', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for Barcelona research option
      final barcelonaButtons = find.textContaining('Barcelona');
      if (barcelonaButtons.evaluate().isNotEmpty) {
        await tester.tap(barcelonaButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('04_barcelona_research_mode');
      } else {
        // Try second radio button if available
        final radioButtons = find.byType(Radio);
        if (radioButtons.evaluate().length > 1) {
          await tester.tap(radioButtons.at(1));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('04_second_option_selected');
        } else {
          await binding.takeScreenshot('04_barcelona_fallback');
        }
      }
    });

    testWidgets('05 - Navigate to Gauteng Research', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for Gauteng research option
      final gautengButtons = find.textContaining('Gauteng');
      if (gautengButtons.evaluate().isNotEmpty) {
        await tester.tap(gautengButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('05_gauteng_research_mode');
      } else {
        // Try third radio button if available
        final radioButtons = find.byType(Radio);
        if (radioButtons.evaluate().length > 2) {
          await tester.tap(radioButtons.at(2));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('05_third_option_selected');
        } else {
          await binding.takeScreenshot('05_gauteng_fallback');
        }
      }
    });

    testWidgets('06 - Main App Navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for navigation elements
      final bottomNavBar = find.byType(BottomNavigationBar);
      final navDrawer = find.byType(Drawer);
      
      if (bottomNavBar.evaluate().isNotEmpty) {
        await binding.takeScreenshot('06_bottom_navigation');
      } else if (navDrawer.evaluate().isNotEmpty) {
        // Try to open drawer
        final menuButton = find.byIcon(Icons.menu);
        if (menuButton.evaluate().isNotEmpty) {
          await tester.tap(menuButton);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('06_navigation_drawer');
        }
      } else {
        await binding.takeScreenshot('06_main_navigation');
      }
    });

    testWidgets('07 - Survey Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for survey-related elements
      final surveyButtons = find.textContaining('Survey');
      final addButtons = find.byIcon(Icons.add);
      final formElements = find.byType(Form);
      
      if (surveyButtons.evaluate().isNotEmpty) {
        await tester.tap(surveyButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('07_survey_interface');
      } else if (addButtons.evaluate().isNotEmpty) {
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('07_add_survey');
      } else if (formElements.evaluate().isNotEmpty) {
        await binding.takeScreenshot('07_form_interface');
      } else {
        await binding.takeScreenshot('07_survey_fallback');
      }
    });

    testWidgets('08 - Map Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for map-related elements
      final mapButtons = find.textContaining('Map');
      final mapIcons = find.byIcon(Icons.map);
      
      if (mapButtons.evaluate().isNotEmpty) {
        await tester.tap(mapButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await binding.takeScreenshot('08_map_interface');
      } else if (mapIcons.evaluate().isNotEmpty) {
        await tester.tap(mapIcons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await binding.takeScreenshot('08_map_via_icon');
      } else {
        await binding.takeScreenshot('08_map_fallback');
      }
    });

    testWidgets('09 - Settings Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for settings elements
      final settingsButtons = find.byIcon(Icons.settings);
      final menuButtons = find.byIcon(Icons.menu);
      
      if (settingsButtons.evaluate().isNotEmpty) {
        await tester.tap(settingsButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('09_settings_interface');
      } else if (menuButtons.evaluate().isNotEmpty) {
        await tester.tap(menuButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('09_menu_interface');
      } else {
        await binding.takeScreenshot('09_settings_fallback');
      }
    });

    testWidgets('10 - Data Upload Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for upload-related elements
      final uploadButtons = find.textContaining('Upload');
      final dataButtons = find.textContaining('Data');
      
      if (uploadButtons.evaluate().isNotEmpty) {
        await tester.tap(uploadButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('10_upload_interface');
      } else if (dataButtons.evaluate().isNotEmpty) {
        await tester.tap(dataButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('10_data_interface');
      } else {
        // Try to navigate through settings to find upload
        final settingsButtons = find.byIcon(Icons.settings);
        if (settingsButtons.evaluate().isNotEmpty) {
          await tester.tap(settingsButtons.first);
          await tester.pumpAndSettle();
          
          final uploadInSettings = find.textContaining('Upload');
          if (uploadInSettings.evaluate().isNotEmpty) {
            await tester.tap(uploadInSettings.first);
            await tester.pumpAndSettle();
            await binding.takeScreenshot('10_upload_from_settings');
          } else {
            await binding.takeScreenshot('10_settings_with_no_upload');
          }
        } else {
          await binding.takeScreenshot('10_upload_fallback');
        }
      }
    });
  });
}
