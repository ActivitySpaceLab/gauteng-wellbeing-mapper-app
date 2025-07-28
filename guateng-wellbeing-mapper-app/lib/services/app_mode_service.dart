import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

/// Service for managing app mode state and transitions
class AppModeService {
  static const String _modeKey = 'app_mode';
  static const String _testingParticipantCodeKey = 'testing_participant_code';
  
  /// Get current app mode
  static Future<AppMode> getCurrentMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_modeKey);
    
    if (modeString == null) {
      return AppMode.private; // Default to private
    }
    
    switch (modeString) {
      case 'private':
        return AppMode.private;
      case 'research':
        return AppMode.research;
      case 'appTesting':
        return AppMode.appTesting;
      default:
        return AppMode.private;
    }
  }

  /// Set current app mode
  static Future<void> setCurrentMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.toString().split('.').last);
    
    // If switching to app testing mode, generate a test participant code
    if (mode == AppMode.appTesting) {
      await _generateTestingParticipantCode();
    }
    
    print('[AppModeService] Mode changed to: ${mode.displayName}');
  }

  /// Generate a fake participant code for testing
  static Future<void> _generateTestingParticipantCode() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testCode = 'TEST_${timestamp.toString().substring(7)}'; // Last 6 digits
    await prefs.setString(_testingParticipantCodeKey, testCode);
  }

  /// Get testing participant code
  static Future<String?> getTestingParticipantCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_testingParticipantCodeKey);
  }

  /// Check if current mode is for testing
  static Future<bool> isTestingMode() async {
    final mode = await getCurrentMode();
    return mode == AppMode.appTesting;
  }

  /// Check if current mode has research features
  static Future<bool> hasResearchFeatures() async {
    final mode = await getCurrentMode();
    return mode.hasResearchFeatures;
  }

  /// Check if current mode sends data to research
  static Future<bool> sendsDataToResearch() async {
    final mode = await getCurrentMode();
    return mode.sendsDataToResearch;
  }

  /// Get mode display info for UI
  static Future<Map<String, dynamic>> getModeDisplayInfo() async {
    final mode = await getCurrentMode();
    return {
      'mode': mode,
      'displayName': mode.displayName,
      'description': mode.description,
      'icon': mode.icon,
      'themeColor': mode.themeColor,
      'showTestingWarnings': mode.showTestingWarnings,
      'isTestingMode': mode == AppMode.appTesting,
    };
  }

  /// Clear all app mode data (for reset)
  static Future<void> clearModeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
    await prefs.remove(_testingParticipantCodeKey);
  }

  /// Get available modes for selection
  static List<AppMode> getAvailableModes() {
    return AppModeExtension.availableModes;
  }

  /// Validate mode transition
  static bool canSwitchToMode(AppMode fromMode, AppMode toMode) {
    // Allow all transitions during beta phase
    return AppModeExtension.availableModes.contains(toMode);
  }
}
