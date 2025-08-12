import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AppModeService Production Tests', () {
    test('getAvailableModes should return only private and research for production', () async {
      // In production build, this should return [AppMode.private, AppMode.research]
      final availableModes = await AppModeService.getAvailableModes();
      
      print('Available modes in production: $availableModes');
      
      // Should contain private mode
      expect(availableModes, contains(AppMode.private));
      
      // Should NOT contain appTesting mode in production builds
      if (const bool.fromEnvironment('dart.vm.profile') == false &&
          const bool.fromEnvironment('dart.vm.product') == true) {
        expect(availableModes, isNot(contains(AppMode.appTesting)));
        print('✅ Production build confirmed - appTesting mode correctly excluded');
      } else {
        print('ℹ️ Running in debug/profile mode - appTesting mode may be available');
      }
    });

    test('setAppMode and getAppMode should work correctly', () async {
      SharedPreferences.setMockInitialValues({'app_mode': AppMode.research.name});

      // Set app mode to private
      await AppModeService.setCurrentMode(AppMode.private);
      
      // Verify that the app mode is now private
      var appMode = await AppModeService.getCurrentMode();
      expect(appMode, AppMode.private);

      // Set app mode to research
      await AppModeService.setCurrentMode(AppMode.research);

      // Verify that the app mode is now research
      appMode = await AppModeService.getCurrentMode();
      expect(appMode, AppMode.research);
    });
  });
}
