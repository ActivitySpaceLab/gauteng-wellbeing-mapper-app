import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling location permissions
class LocationService {
  
  /// Request location permissions from the user
  static Future<bool> requestLocationPermissions({BuildContext? context}) async {
    try {
      print('[LocationService] Requesting location permissions...');
      
      // Check current permission status
      final status = await Permission.locationWhenInUse.status;
      print('[LocationService] Current permission status: $status');
      
      if (status == PermissionStatus.granted) {
        return true;
      }
      
      // Request permission
      final result = await Permission.locationWhenInUse.request();
      print('[LocationService] Permission request result: $result');
      
      return result == PermissionStatus.granted;
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
      
      // Show rationale dialog first if context is provided
      if (context != null) {
        bool userAccepted = await showBackgroundLocationRationale(context);
        if (!userAccepted) {
          print('[LocationService] User declined background location rationale');
          return false;
        }
      }
      
      // Check current permission status
      final status = await Permission.locationAlways.status;
      print('[LocationService] Current background location status: $status');
      
      if (status == PermissionStatus.granted) {
        return true;
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
      
      // Request basic location permission using the original method
      bool hasLocationPermission = await requestLocationPermissions(context: context);
      
      if (hasLocationPermission) {
        // Request precise location for better accuracy
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
