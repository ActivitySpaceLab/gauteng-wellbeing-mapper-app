import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'ios_location_fix_service.dart';

/// Service for handling location permissions
class LocationService {
  
  /// Request location permissions from the user
  static Future<bool> requestLocationPermissions({BuildContext? context}) async {
    try {
      print('[LocationService] Requesting location permissions...');
      
      // Check current permission status first
      final whenInUseStatus = await Permission.locationWhenInUse.status;
      final alwaysStatus = await Permission.locationAlways.status;
      print('[LocationService] Current when-in-use status: $whenInUseStatus');
      print('[LocationService] Current always status: $alwaysStatus');
      
      // If we already have either when-in-use or always permission, we're good
      if (whenInUseStatus == PermissionStatus.granted || alwaysStatus == PermissionStatus.granted) {
        print('[LocationService] Location permission already granted');
        return true;
      }
      
      // For iOS, try the comprehensive fix first
      if (!kIsWeb && context != null) {
        try {
          final platform = Theme.of(context).platform;
          if (platform == TargetPlatform.iOS) {
            print('[LocationService] Checking iOS native permission status first...');
            
            // First, quickly check if native iOS permissions are already working
            final nativePermission = await IosLocationFixService.checkNativeLocationPermission();
            final isRegistered = await IosLocationFixService.isAppRegisteredInSettings();
            
            if (nativePermission || isRegistered) {
              print('[LocationService] iOS native permissions already working, skipping comprehensive fix');
              return true;
            }
            
            print('[LocationService] iOS permissions not working, running comprehensive fix...');
            final iosFixResult = await IosLocationFixService.performComprehensiveFix(context: context);
            if (iosFixResult) {
              print('[LocationService] iOS fix successful');
              
              // Double-check with native iOS permission status
              final newNativePermission = await IosLocationFixService.checkNativeLocationPermission();
              print('[LocationService] Native iOS permission check: $newNativePermission');
              
              if (newNativePermission) {
                print('[LocationService] Native iOS permissions confirmed - bypassing permission_handler');
                return true;
              }
              
              // Check if app is registered even if permission_handler reports denied
              final newIsRegistered = await IosLocationFixService.isAppRegisteredInSettings();
              if (newIsRegistered) {
                print('[LocationService] App registered in iOS settings - assuming permissions are working');
                return true;
              }
              
              // Double-check permissions after iOS fix
              final newWhenInUseStatus = await Permission.locationWhenInUse.status;
              final newAlwaysStatus = await Permission.locationAlways.status;
              print('[LocationService] After iOS fix - when-in-use: $newWhenInUseStatus, always: $newAlwaysStatus');
              if (newWhenInUseStatus == PermissionStatus.granted || newAlwaysStatus == PermissionStatus.granted) {
                return true;
              }
            } else {
              print('[LocationService] iOS fix failed, falling back to standard approach');
            }
          }
        } catch (e) {
          print('[LocationService] iOS fix error, falling back: $e');
        }
      }
      
      // Standard permission request (fallback or non-iOS)
      print('[LocationService] Attempting standard permission request...');
      final result = await Permission.locationWhenInUse.request();
      print('[LocationService] Permission request result: $result');
      
      // Final check - accept both when-in-use and always permissions
      final finalWhenInUseStatus = await Permission.locationWhenInUse.status;
      final finalAlwaysStatus = await Permission.locationAlways.status;
      print('[LocationService] Final status check - when-in-use: $finalWhenInUseStatus, always: $finalAlwaysStatus');
      
      return finalWhenInUseStatus == PermissionStatus.granted || finalAlwaysStatus == PermissionStatus.granted;
    } catch (error) {
      print('[LocationService] Error requesting location permissions: $error');
      return false;
    }
  }

  /// Request precise location permissions (Android only)
  static Future<bool> requestPreciseLocationPermission() async {
    try {
      print('[LocationService] Requesting precise location permission...');
      
      // Check if device supports precise location (Android only)
      if (await Permission.locationAlways.status == PermissionStatus.granted) {
        return true;
      }
      
      final result = await Permission.locationAlways.request();
      print('[LocationService] Precise location permission result: $result');
      
      return result == PermissionStatus.granted;
    } catch (error) {
      print('[LocationService] Error requesting precise location permission: $error');
      return false;
    }
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      print('[LocationService] Location permission status: $status');
      return status == PermissionStatus.granted;
    } catch (error) {
      print('[LocationService] Error checking location permission: $error');
      return false;
    }
  }

  /// Show background location rationale dialog before requesting permission
  static Future<bool> showBackgroundLocationRationale(BuildContext context) async {
    bool userAccepted = false;
    
    await showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissing the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Background Location Access'),
          content: const Text(
            'Wellbeing Mapper uses the device\'s location to track your movement even when you have the app closed so that you build up a clear map of where you spend time, which you can compare to your wellbeing responses.\n\n'
            'In the next dialog, please select "Allow all the time" to enable this feature.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now'),
              onPressed: () {
                userAccepted = false;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Skip'),
              onPressed: () {
                userAccepted = false;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                userAccepted = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    
    return userAccepted;
  }

  /// Request background location permissions with user education
  static Future<bool> requestBackgroundLocationPermissions({BuildContext? context}) async {
    try {
      print('[LocationService] Requesting background location permissions...');
      
      // Check current permission status first
      final status = await Permission.locationAlways.status;
      print('[LocationService] Current background location status: $status');
      
      if (status == PermissionStatus.granted) {
        print('[LocationService] Background location already granted');
        return true;
      }
      
      // Show rationale dialog only if context is provided AND permission is not already granted
      if (context != null) {
        bool userAccepted = await showBackgroundLocationRationale(context);
        if (!userAccepted) {
          print('[LocationService] User declined background location rationale');
          return false;
        }
      }
      
      // Request permission
      final result = await Permission.locationAlways.request();
      print('[LocationService] Background location request result: $result');
      
      return result == PermissionStatus.granted;
    } catch (error) {
      print('[LocationService] Error requesting background location permissions: $error');
      return false;
    }
  }

  /// Initialize location services - call this when the app starts
  static Future<bool> initializeLocationServices({BuildContext? context}) async {
    try {
      print('[LocationService] Initializing location services...');
      
      // Handle web platform - location services work differently on web
      if (kIsWeb) {
        print('[LocationService] Web platform detected - skipping mobile location permissions');
        print('[LocationService] Web geolocation will be handled by browser permissions');
        return true; // Allow web app to proceed without mobile location permissions
      }
      
      // Check if we already have any location permission (when-in-use or always)
      final whenInUseStatus = await Permission.locationWhenInUse.status;
      final alwaysStatus = await Permission.locationAlways.status;
      print('[LocationService] Current permissions - when-in-use: $whenInUseStatus, always: $alwaysStatus');
      
      if (whenInUseStatus == PermissionStatus.granted || alwaysStatus == PermissionStatus.granted) {
        print('[LocationService] Location permission already available - all location services available');
        return true;
      }
      
      // For iOS, also check native permission status (sometimes permission_handler is out of sync)
      if (context != null) {
        try {
          final platform = Theme.of(context).platform;
          if (platform == TargetPlatform.iOS) {
            final nativePermission = await IosLocationFixService.checkNativeLocationPermission();
            final isRegistered = await IosLocationFixService.isAppRegisteredInSettings();
            
            if (nativePermission || isRegistered) {
              print('[LocationService] iOS native permissions already working, skipping permission requests');
              return true;
            }
          }
        } catch (e) {
          print('[LocationService] Error checking iOS native permissions: $e');
        }
      }
      
      // Request basic location permission first
      bool hasLocationPermission = await requestLocationPermissions(context: context);
      
      // For iOS, double-check with native permission status if permission_handler failed
      if (!hasLocationPermission && !kIsWeb && context != null) {
        try {
          final platform = Theme.of(context).platform;
          if (platform == TargetPlatform.iOS) {
            print('[LocationService] Permission handler failed, checking native iOS status...');
            final nativePermission = await IosLocationFixService.checkNativeLocationPermission();
            if (nativePermission) {
              print('[LocationService] Native iOS permissions available despite permission_handler failure');
              hasLocationPermission = true;
            }
          }
        } catch (e) {
          print('[LocationService] Error checking native iOS permissions: $e');
        }
      }
      
      if (hasLocationPermission) {
        print('[LocationService] Location permission granted');
        
        // Request precise location for better accuracy (Android only)
        await requestPreciseLocationPermission();
        
        // Request background location for continuous tracking
        await requestBackgroundLocationPermissions(context: context);
        
        print('[LocationService] Location services initialized successfully');
        return true;
      } else {
        print('[LocationService] Failed to get location permission');
        return false;
      }
    } catch (error) {
      print('[LocationService] Error initializing location services: $error');
      return false;
    }
  }

}
