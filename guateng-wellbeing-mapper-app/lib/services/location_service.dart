import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service for handling location permissions
class LocationService {
  
  /// Request location permissions from the user
  static Future<bool> requestLocationPermissions({BuildContext? context}) async {
    try {
      print('[LocationService] Checking current location permission status...');
      
      // Check current permission status
      PermissionStatus status = await Permission.location.status;
      print('[LocationService] Current location permission status: $status');
      
      // If already granted, return true
      if (status == PermissionStatus.granted) {
        print('[LocationService] Location permission already granted');
        return true;
      }
      
      // If permission is denied permanently, we can't request it again
      if (status == PermissionStatus.permanentlyDenied) {
        print('[LocationService] Location permission permanently denied');
        if (context != null) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      }
      
      // Request location permission
      print('[LocationService] Requesting location permission...');
      PermissionStatus result = await Permission.location.request();
      print('[LocationService] Location permission request result: $result');
      
      if (result == PermissionStatus.granted) {
        print('[LocationService] Location permission granted');
        return true;
      } else if (result == PermissionStatus.permanentlyDenied) {
        print('[LocationService] Location permission permanently denied after request');
        if (context != null) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      } else {
        print('[LocationService] Location permission denied: $result');
        if (context != null) {
          await _showPermissionDeniedDialog(context, isPermanent: false);
        }
        return false;
      }
    } catch (error) {
      print('[LocationService] Error requesting location permission: $error');
      return false;
    }
  }

  /// Request precise location permissions (Android only)
  static Future<bool> requestPreciseLocationPermission() async {
    try {
      print('[LocationService] Checking precise location permission...');
      
      // First ensure we have basic location permission
      bool hasBasicLocation = await requestLocationPermissions();
      if (!hasBasicLocation) {
        return false;
      }
      
      // Request precise location (this is mainly for Android 12+)
      PermissionStatus preciseStatus = await Permission.locationWhenInUse.request();
      print('[LocationService] Precise location permission result: $preciseStatus');
      
      return preciseStatus == PermissionStatus.granted;
    } catch (error) {
      print('[LocationService] Error requesting precise location permission: $error');
      return false;
    }
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (error) {
      print('[LocationService] Error checking location permission: $error');
      return false;
    }
  }

  /// Show dialog explaining why location permission is needed
  static Future<void> _showPermissionDeniedDialog(BuildContext context, {bool isPermanent = true}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
            isPermanent 
              ? 'This app needs location permission to track your wellbeing locations. Please enable location permission in your device settings.'
              : 'This app needs location permission to track your wellbeing locations. Location tracking is essential for the research study and wellbeing mapping features.',
          ),
          actions: <Widget>[
            if (isPermanent)
              TextButton(
                child: Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            TextButton(
              child: Text(isPermanent ? 'Cancel' : 'OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Show background location rationale dialog before requesting permission
  static Future<bool> showBackgroundLocationRationale(BuildContext context) async {
    bool userAccepted = false;
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
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
      print('[LocationService] Checking background location permission...');
      
      // First ensure we have basic location permission
      bool hasBasicLocation = await requestLocationPermissions(context: context);
      if (!hasBasicLocation) {
        print('[LocationService] Cannot request background location without basic location permission');
        return false;
      }
      
      // Check current background location permission status
      PermissionStatus backgroundStatus = await Permission.locationAlways.status;
      print('[LocationService] Current background location permission status: $backgroundStatus');
      
      // If already granted, return true
      if (backgroundStatus == PermissionStatus.granted) {
        print('[LocationService] Background location permission already granted');
        return true;
      }
      
      // Show rationale dialog if context is available
      if (context != null) {
        bool userAccepted = await showBackgroundLocationRationale(context);
        if (!userAccepted) {
          print('[LocationService] User declined background location rationale');
          return false;
        }
      }
      
      // Request background location permission
      print('[LocationService] Requesting background location permission...');
      PermissionStatus result = await Permission.locationAlways.request();
      print('[LocationService] Background location permission request result: $result');
      
      if (result == PermissionStatus.granted) {
        print('[LocationService] Background location permission granted');
        return true;
      } else {
        print('[LocationService] Background location permission denied: $result');
        return false;
      }
    } catch (error) {
      print('[LocationService] Error requesting background location permission: $error');
      return false;
    }
  }

  /// Initialize location services - call this when the app starts
  static Future<bool> initializeLocationServices({BuildContext? context}) async {
    try {
      print('[LocationService] Initializing location services...');
      
      // Request basic location permission
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
