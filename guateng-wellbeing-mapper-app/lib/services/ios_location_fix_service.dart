import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../main.dart'; // Import to access existing navigatorKey

/// iOS-specific location service to fix permission registration issues
class IosLocationFixService {
  static const _channel = MethodChannel('com.github.activityspacelab.wellbeingmapper.guateng/ios_location');
  
  /// Initialize native iOS location manager to ensure app appears in settings
  static Future<bool> initializeNativeLocationManager() async {
    try {
      print('[IosLocationFixService] Initializing native iOS location manager...');
      
      // Call native iOS method to initialize CLLocationManager
      final result = await _channel.invokeMethod('initializeLocationManager');
      print('[IosLocationFixService] Native initialization result: $result');
      
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to initialize native location manager: $e');
      return false;
    }
  }
  
  /// Request location permission using native iOS methods
  static Future<bool> requestLocationPermissionNative() async {
    try {
      print('[IosLocationFixService] Requesting location permission via native iOS...');
      
      // First initialize the native location manager
      await initializeNativeLocationManager();
      
      // Then request permission using native methods
      final result = await _channel.invokeMethod('requestLocationPermission');
      print('[IosLocationFixService] Native permission request result: $result');
      
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to request permission via native iOS: $e');
      return false;
    }
  }
  
  /// Check if app is registered in iOS location settings
  static Future<bool> isAppRegisteredInSettings() async {
    try {
      final result = await _channel.invokeMethod('isAppRegisteredInSettings');
      print('[IosLocationFixService] App registered in settings: $result');
      return result == true;
    } catch (e) {
      print('[IosLocationFixService] Failed to check settings registration: $e');
      return false;
    }
  }
  
  /// Force app to appear in iOS location settings
  static Future<bool> forceRegisterInSettings() async {
    try {
      print('[IosLocationFixService] Force registering app in iOS location settings...');
      
      // Step 1: Initialize native location manager
      await initializeNativeLocationManager();
      
      // Step 2: Request location permission
      await requestLocationPermissionNative();
      
      // Step 3: Initialize background geolocation to trigger additional registration
      try {
        await bg.BackgroundGeolocation.ready(bg.Config(
          desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
          distanceFilter: 10.0,
          stopOnTerminate: false,
          startOnBoot: true,
          debug: false,
          logLevel: bg.Config.LOG_LEVEL_OFF,
        ));
        print('[IosLocationFixService] Background geolocation ready');
      } catch (bgError) {
        print('[IosLocationFixService] Background geolocation error (non-critical): $bgError');
      }
      
      // Step 4: Use permission_handler as backup
      final permissionResult = await Permission.locationWhenInUse.request();
      print('[IosLocationFixService] Permission handler result: $permissionResult');
      
      // Step 5: Check if now registered
      final isRegistered = await isAppRegisteredInSettings();
      print('[IosLocationFixService] Force registration result: $isRegistered');
      
      return isRegistered;
    } catch (e) {
      print('[IosLocationFixService] Failed to force register in settings: $e');
      return false;
    }
  }
  
  /// Comprehensive iOS location fix - call this during app initialization
  static Future<bool> performComprehensiveFix({BuildContext? context}) async {
    try {
      print('[IosLocationFixService] Starting comprehensive iOS location fix...');
      
      // Skip on non-iOS platforms
      if (kIsWeb) {
        print('[IosLocationFixService] Web platform, skipping fix');
        return true;
      }
      
      // Check if iOS platform
      final currentContext = context ?? navigatorKey.currentContext;
      if (currentContext == null) {
        print('[IosLocationFixService] No context available');
        return false;
      }
      
      final platform = Theme.of(currentContext).platform;
      if (platform != TargetPlatform.iOS) {
        print('[IosLocationFixService] Not iOS platform ($platform), skipping fix');
        return true;
      }
      
      // Step 1: Check current status
      final currentStatus = await Permission.locationWhenInUse.status;
      print('[IosLocationFixService] Current permission status: $currentStatus');
      
      // Step 2: Check if already registered in settings
      final isRegistered = await isAppRegisteredInSettings();
      print('[IosLocationFixService] Currently registered in settings: $isRegistered');
      
      if (isRegistered && currentStatus == PermissionStatus.granted) {
        print('[IosLocationFixService] Already properly configured');
        return true;
      }
      
      // Step 3: Force registration if needed
      if (!isRegistered) {
        print('[IosLocationFixService] App not in settings, forcing registration...');
        final registrationResult = await forceRegisterInSettings();
        
        if (!registrationResult) {
          print('[IosLocationFixService] Failed to register app in settings');
          return false;
        }
      }
      
      // Step 4: Final permission request if needed
      if (currentStatus != PermissionStatus.granted) {
        print('[IosLocationFixService] Requesting final permission...');
        final finalResult = await Permission.locationWhenInUse.request();
        print('[IosLocationFixService] Final permission result: $finalResult');
        return finalResult == PermissionStatus.granted;
      }
      
      return true;
    } catch (e) {
      print('[IosLocationFixService] Comprehensive fix failed: $e');
      return false;
    }
  }
}
