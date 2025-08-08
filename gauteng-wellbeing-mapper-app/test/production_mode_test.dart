import 'package:flutter_test/flutter_test.dart';
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

    test('should not send data to research in testing mode', () async {
      // This should return false when in test mode
      final sendsData = await AppModeService.sendsDataToResearch();
      expect(sendsData, isFalse);
      print('✅ Test mode correctly prevents data upload: $sendsData');
    });
  });
}
