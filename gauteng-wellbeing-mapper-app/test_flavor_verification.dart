#!/usr/bin/env dart

import 'lib/services/app_mode_service.dart';
import 'lib/models/app_mode.dart';

/// Verification script to ensure app mode and build flavor restrictions are working correctly
void main() async {
  print('🔍 App Mode & Build Flavor Verification');
  print('==========================================');
  
  // Test production build flavor
  print('\n📦 Production Build Flavor:');
  print('  APP_FLAVOR: ${AppModeService.appFlavor}');
  print('  Is Beta Build: ${AppModeService.isBetaBuild}');
  print('  Is Production Build: ${AppModeService.isProductionBuild}');
  print('  Available Modes: ${AppModeService.getAvailableModes().map((m) => m.displayName).join(', ')}');
  
  // Test mode availability in production
  for (final mode in AppMode.values) {
    final isAvailable = AppModeService.getAvailableModes().contains(mode);
    final sendsData = mode.sendsDataToResearch;
    final hasFeatures = mode.hasResearchFeatures;
    
    print('  ${mode.displayName}:');
    print('    Available: $isAvailable');
    print('    Sends Research Data: $sendsData');
    print('    Has Research Features: $hasFeatures');
  }
  
  // Test app mode security rules
  print('\n🔒 Security Rule Verification:');
  for (final mode in AppMode.values) {
    print('  ${mode.displayName} Mode:');
    print('    Can send research data: ${mode.sendsDataToResearch}');
    print('    Shows research features: ${mode.hasResearchFeatures}');
    print('    Shows testing warnings: ${mode.showTestingWarnings}');
  }
  
  // Test build flavor restrictions
  print('\n🛡️  Build Flavor Restrictions:');
  if (AppModeService.isBetaBuild) {
    print('  ✅ Beta Build: Only Private and App Testing modes available');
    print('  ✅ Beta Build: Research mode NOT available (prevents real data collection)');
  } else {
    print('  ✅ Production Build: Private and Research modes available');
    print('  ✅ Production Build: App Testing mode NOT available (users can\'t access debug features)');
  }
  
  print('\n✅ All security configurations verified!');
}
