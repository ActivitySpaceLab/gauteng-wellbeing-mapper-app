import 'package:wellbeing_mapper/services/notification_service.dart';
import 'package:wellbeing_mapper/services/location_service.dart';
import 'package:wellbeing_mapper/services/initial_survey_service.dart';
import 'package:wellbeing_mapper/services/survey_navigation_service.dart';
import 'package:wellbeing_mapper/ui/side_drawer.dart';
import 'package:wellbeing_mapper/util/env.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';
import 'package:wellbeing_mapper/util/onboarding_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:background_fetch/background_fetch.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import 'map_view.dart';
import '../services/ios_location_fix_service.dart';

import '../util/dialog.dart' as util;

// For pretty-printing location JSON
JsonEncoder encoder = new JsonEncoder.withIndent("     ");

/// The main home-screen of the AdvancedApp.  Builds the Scaffold of the App.
///
class HomeView extends StatefulWidget {
  HomeView(this.appName) {
    print('[home_view.dart] HomeView constructor called with appName: $appName');
  }
  final String appName;

  @override
  State createState() {
    print('[home_view.dart] HomeView createState called');
    return HomeViewState(appName);
  }
}

class HomeViewState extends State<HomeView>
    with TickerProviderStateMixin<HomeView>, WidgetsBindingObserver {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  
  // Static flag to prevent multiple background geolocation configurations
  static bool _backgroundGeoConfigured = false;
  
  //late TabController _tabController;

  late String appName;
  //late bool _isMoving;
  late bool _enabled;
  //late String _motionActivity;
  //late String _odometer;
  Timer? _surveyPromptTimer;

  HomeViewState(this.appName) {
    print('[home_view.dart] HomeViewState constructor called with appName: $appName');
  }

  @override
  void initState() {
    super.initState();
    print('[home_view.dart] HomeView initState called');
    WidgetsBinding.instance.addObserver(this);

    _enabled = true;

    // Debug: Try to load participation settings

    SharedPreferences.getInstance().then((prefs) {
      final settings = prefs.getString('participation_settings');
      print('[home_view.dart] participation_settings in HomeView: '
          '${settings ?? 'null'}');
      if (settings != null) {
        try {
          final decoded = jsonDecode(settings);
          print('[home_view.dart] participation_settings decoded: $decoded');
          print('[home_view.dart] isResearchParticipant: ${decoded['isResearchParticipant']}');
        } catch (e) {
          print('[home_view.dart] ERROR decoding participation_settings: $e');
        }
      }
    });

    initPlatformState();
    _checkForPendingSurveyPrompt();
    _checkForIncompleteInitialSurvey();
    _checkAndShowOnboarding();
  }

  // Check if this is the first time using the app and show onboarding
  void _checkAndShowOnboarding() async {
    // Wait a bit longer for the widget to be fully built and other dialogs to clear
    Timer(Duration(seconds: 2), () async {
      if (mounted) {
        bool shouldShow = await OnboardingHelper.shouldShowOnboarding();
        if (shouldShow && mounted) {
          OnboardingHelper.showQuickTour(context);
        }
      }
    });
  }

  // Check for pending survey prompts and show dialog if needed
  void _checkForPendingSurveyPrompt() {
    // Wait a bit for the widget to be fully built
    _surveyPromptTimer = Timer(Duration(milliseconds: 500), () async {
      if (mounted) {
        bool hasPendingPrompt = await NotificationService.hasPendingSurveyPrompt();
        if (hasPendingPrompt && mounted) {
          await NotificationService.showSurveyPromptDialog(context);
        }
      }
    });
  }

  // Check if research/testing user needs to complete initial survey
  void _checkForIncompleteInitialSurvey() {
    // Wait a bit to allow widget to build, but shorter for fresh consent users
    Timer(Duration(seconds: 2), () async {
      if (mounted) {
        print('[HomeView] Checking for incomplete initial survey...');
        bool needsInitialSurvey = await InitialSurveyService.needsInitialSurvey();
        print('[HomeView] needsInitialSurvey: $needsInitialSurvey');
        
        if (needsInitialSurvey && mounted) {
          
          // Check if this is a fresh consent completion (user just came from consent form)
          final prefs = await SharedPreferences.getInstance();
          bool isFirstTime = prefs.getBool('fresh_consent_completion') ?? false;
          print('[HomeView] isFirstTime (fresh_consent_completion): $isFirstTime');
          
          if (isFirstTime) {
            // Clear the flag and show immediate survey popup
            await prefs.remove('fresh_consent_completion');
            print('[HomeView] Showing immediate initial survey offering');
            _showInitialSurveyOffering();
          } else {
            // Check if we should show a reminder (respects timing intervals)
            String? reminderMessage = await InitialSurveyService.shouldShowReminder();
            print('[HomeView] reminderMessage: $reminderMessage');
            if (reminderMessage != null) {
              print('[HomeView] Showing initial survey reminder');
              _showInitialSurveyReminder(reminderMessage);
            }
          }
        } else {
          print('[HomeView] No initial survey needed or widget not mounted');
        }
      }
    });
  }

  // Show immediate survey offering for fresh consent users
  void _showInitialSurveyOffering() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Complete Initial Survey'),
        content: Text(
          'Would you like to complete the initial demographic survey now? '
          'This helps us understand our participants better, but you can also do it later.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // User declined, they can do it later via regular reminders
            },
            child: Text('No, I\'ll do it later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Navigate to initial survey using SurveyNavigationService
              SurveyNavigationService.navigateToInitialSurvey(context);
              
              // Note: For Qualtrics surveys, completion tracking will need to be updated
              // The current completion tracking only works for hardcoded surveys
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Yes, complete now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInitialSurveyReminder(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Initial Survey'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Navigate to initial survey using SurveyNavigationService
              SurveyNavigationService.navigateToInitialSurvey(context);
              
              // Note: For Qualtrics surveys, completion tracking will need to be updated
              // The current completion tracking only works for hardcoded surveys
            },
            child: Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  void _showPermissionError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlwaysPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Background Location Required'),
        content: Text(
          'To track your location continuously, this app needs "Always" location permission. '
          'Please go to Settings > Privacy & Security > Location Services > Wellbeing Mapper '
          'and select "Always".'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open app settings
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Debug method to check background geolocation state
  Future<void> _debugBackgroundGeolocationState() async {
    try {
      bg.State state = await bg.BackgroundGeolocation.state;
      print('[DEBUG] Background Geolocation State: ${state.toMap()}');
      
      // Check plugin properties
      print('[DEBUG] Enabled: ${state.enabled}');
      print('[DEBUG] Tracking mode: ${state.trackingMode}');
      print('[DEBUG] Distance filter: ${state.distanceFilter}');
      print('[DEBUG] Desired accuracy: ${state.desiredAccuracy}');
      print('[DEBUG] Stop on terminate: ${state.stopOnTerminate}');
      print('[DEBUG] Start on boot: ${state.startOnBoot}');
      print('[DEBUG] URL: ${state.url}');
      print('[DEBUG] Schedule: ${state.schedule}');
      
    } catch (e) {
      print('[DEBUG] Error getting background geolocation state: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("[home_view didChangeAppLifecycleState] : $state");
    //TODO: The interior of these 'if statements' is empty
    if (state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {}
  }

  void initPlatformState() async {
    print('[home_view.dart] initPlatformState starting');
    try {
      SharedPreferences prefs = await _prefs;
      String? sampleId = prefs.getString("sample_id");
      String? userUUID = prefs.getString("user_uuid");
      String? participationSettings = prefs.getString("participation_settings");

      print('[home_view.dart] initPlatformState - sampleId: $sampleId, userUUID: $userUUID');
      print('[home_view.dart] initPlatformState - participationSettings: $participationSettings');

      if (sampleId == null || userUUID == null) {
        print('[home_view.dart] initPlatformState - creating new UUID/sampleId');
        prefs.setString("user_uuid", Uuid().v4());
        prefs.setString("sample_id", ENV.DEFAULT_SAMPLE_ID);
        userUUID = prefs.getString("user_uuid");
        sampleId = prefs.getString("sample_id");
      }

        // Configure background geolocation for ALL users (private and research)
        // The difference is in server sync settings, not location tracking capability
        // Only configure once to prevent multiple initializations
        if (!_backgroundGeoConfigured) {
          try {
            // Skip background geolocation configuration on web platform
            if (kIsWeb) {
              print('[home_view.dart] Web platform detected - skipping background geolocation configuration');
              _backgroundGeoConfigured = true; // Mark as configured to prevent retries
            } else {
              // Always configure background geolocation first, regardless of permissions
              // This initializes the plugin so it can be started later when permissions are granted
              _configureBackgroundGeolocation(userUUID, sampleId);
              _backgroundGeoConfigured = true;
              print('[home_view.dart] Background geolocation configured');
              
              // Then request location permissions
              try {
                bool hasLocationPermission = await LocationService.initializeLocationServices(context: context);
                if (hasLocationPermission) {
                  print('[home_view.dart] Location permission granted during initialization');
                } else {
                  print('[home_view.dart] Location permission not granted during initialization, user can enable later via switch');
                }
              } catch (error) {
                print('[home_view.dart] Error during location permission initialization: $error');
                // Continue - user can still grant permissions later via the switch
              }
            }
          } catch (error) {
            print('[home_view.dart] Error during location initialization: $error');
            // Continue with app initialization even if location setup fails
          }
        } else {
          print('[home_view.dart] Background geolocation already configured, skipping');
        }

      // Only configure background services if user has completed participation selection
      if (participationSettings != null && participationSettings.isNotEmpty) {
        try {
          final participationData = jsonDecode(participationSettings);
          final isResearchParticipant = participationData['isResearchParticipant'] ?? false;
          
          print('[home_view.dart] initPlatformState - User participation status: ${isResearchParticipant ? "Research Participant" : "Private User"}');
          
          // ALL users need background geolocation for tracking, but configured differently
          // Move to async to avoid blocking UI
          _configureBackgroundServicesAsync(userUUID, sampleId, isResearchParticipant);
          
        } catch (e) {
          print('[home_view.dart] Error parsing participation settings: $e');
          // Default to private user configuration on error
          _configureBackgroundServicesAsync(userUUID, sampleId, false);
        }
      } else {
        print('[home_view.dart] Participation settings not found, background services will be configured when user makes choice');
        // Location permissions are already requested above, no need to call again
      }
      print('[home_view.dart] initPlatformState completed successfully');
    } catch (error) {
      print('[home_view.dart] Error in initPlatformState: $error');
    }
  }

 
  // ignore: non_constant_identifier_names
  void _configureBackgroundGeolocation(user_uuid, sample_id) async {
    // 1.  Listen to events (See docs for all 13 available events).
    bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
//    bg.BackgroundGeolocation.onActivityChange(_onActivityChange);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onHttp(_onHttp);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    bg.BackgroundGeolocation.onHeartbeat(_onHeartbeat);
    bg.BackgroundGeolocation.onGeofence(_onGeofence);
    bg.BackgroundGeolocation.onSchedule(_onSchedule);
    bg.BackgroundGeolocation.onPowerSaveChange(_onPowerSaveChange);
    bg.BackgroundGeolocation.onEnabledChange(_onEnabledChange);
    bg.BackgroundGeolocation.onNotificationAction(_onNotificationAction);

    // 2.  Configure the plugin
    bg.BackgroundGeolocation.ready(bg.Config(
            // Convenience option to automatically configure the SDK to post to Transistor Demo server.
            // Logging & Debug
            reset: false,
            debug: true, // Enable debug to see more detailed logs
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            // Geolocation options
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_NAVIGATION,
            distanceFilter: 10.0,
            stopTimeout: 1,
            // HTTP & Persistence
            autoSync: false,
            persistMode: bg.Config.PERSIST_MODE_ALL,
            maxDaysToPersist: 30,
            maxRecordsToPersist: -1,
            // Application options
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
            heartbeatInterval: 60))
        .then((bg.State state) {
      print('[ready] Background geolocation ready with state: ${state.toMap()}');
      print('[ready] Plugin enabled: ${state.enabled}');
      print('[ready] Tracking mode: ${state.trackingMode}');
      print('[ready] Distance filter: ${state.distanceFilter}');

      if (state.schedule!.isNotEmpty) {
        bg.BackgroundGeolocation.startSchedule();
        print('[ready] Started schedule');
      }
      setState(() {
        _enabled = state.enabled;
        //_isMoving = state.isMoving!;
      });
      print('[ready] Background geolocation configuration complete');
    }).catchError((error) {
      print('[ready] CRITICAL ERROR configuring background geolocation: $error');
      // Set a flag to indicate configuration failed
      setState(() {
        _backgroundGeoConfigured = false;
      });
    });
  }

  // Configure BackgroundFetch (not required by BackgroundGeolocation).
  void _configureBackgroundFetch() async {
    try {
      print("Configuring BackgroundFetch");
      BackgroundFetch.configure(
          BackgroundFetchConfig(
              minimumFetchInterval: 15,
              startOnBoot: true,
              stopOnTerminate: false,
              enableHeadless: true,
              requiresStorageNotLow: false,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiredNetworkType: NetworkType.NONE), (String taskId) async {
        print("[BackgroundFetch] received event $taskId");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int count = 0;
        if (prefs.get("fetch-count") != null) {
          count = prefs.getInt("fetch-count")!;
        }
        prefs.setInt("fetch-count", ++count);
        print('[BackgroundFetch] count: $count');

        //If condition below commented out by Otis, not sure how or why taskId would have this value
        //if (taskId == 'flutter_background_fetch') {
        // Test scheduling a custom-task in fetch event.
        BackgroundFetch.scheduleTask(TaskConfig(
            taskId: "com.transistorsoft.wellbeingmapper",
            delay: 5000,
            periodic: false,
            forceAlarmManager: true,
            stopOnTerminate: false,
            enableHeadless: true));
        //}
        BackgroundFetch.finish(taskId);
      });
    } catch (error) {
      print('[_configureBackgroundFetch] ERROR: $error');
    }
/*
    // Test scheduling a custom-task.
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.wellbeingmapper",
        delay: 10000,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true));
        */
  }

  // Configure background services asynchronously to avoid blocking UI
  void _configureBackgroundServicesAsync(user_uuid, sample_id, bool isResearchParticipant) async {
    print('[home_view.dart] Starting async background services configuration for ${isResearchParticipant ? "research participant" : "private user"}');
    try {
      // Schedule background service configuration for next frame to avoid blocking UI
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(Duration(milliseconds: 100)); // Small delay to ensure UI renders
        
        // Configure BackgroundFetch
        _configureBackgroundFetch();
      });
    } catch (error) {
      print('[home_view.dart] Error in _configureBackgroundServicesAsync: $error');
    }
  }

  void _onClickEnable(enabled) async {
    // Skip background geolocation operations on web platform
    if (kIsWeb) {
      print('[_onClickEnable] Web platform detected - skipping background geolocation operations');
      setState(() {
        _enabled = enabled; // Update UI state only
      });
      return;
    }
    
    // Ensure background geolocation is configured before proceeding
    if (!_backgroundGeoConfigured) {
      print('[_onClickEnable] Background geolocation not configured yet, cannot start tracking');
      setState(() {
        _enabled = false;
      });
      _showPermissionError('Location tracking is not properly initialized. Please restart the app and try again.');
      return;
    }
    
    if (enabled) {
      // Set enabled to true first to show user we're trying to start
      setState(() {
        _enabled = true;
      });
      
      // Check if we have the necessary permissions before starting tracking
      try {
        // On iOS, use the comprehensive location fix service first to handle permission issues
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          print('[_onClickEnable] iOS detected, checking with IosLocationFixService first...');
          
          // Check if native iOS permissions are working (bypasses Flutter plugin issues)
          final hasNativePermission = await IosLocationFixService.checkNativeLocationPermission();
          final isRegistered = await IosLocationFixService.isAppRegisteredInSettings();
          
          print('[_onClickEnable] Native permission check: $hasNativePermission, registered: $isRegistered');
          
          // If native permissions are working, proceed with tracking
          if (hasNativePermission || isRegistered) {
            print('[_onClickEnable] ✅ Native iOS permissions confirmed, starting tracking directly');
            
            try {
              bg.State state = await bg.BackgroundGeolocation.state;
              print('[_onClickEnable] Current BG state before start: $state');
              
              if (state.trackingMode == 1) {
                print('[_onClickEnable] Starting background geolocation (tracking mode)...');
                await bg.BackgroundGeolocation.start();
              } else {
                print('[_onClickEnable] Starting geofences...');
                await bg.BackgroundGeolocation.startGeofences();
              }
              
              // Get the final state after starting
              bg.State finalState = await bg.BackgroundGeolocation.state;
              print('[_onClickEnable] Final BG state after start: $finalState');
              
              setState(() {
                _enabled = finalState.enabled;
              });
              
              if (!finalState.enabled) {
                print('[_onClickEnable] WARNING: Background geolocation failed to start even with native permissions');
                _showPermissionError('Failed to start location tracking. Please check your location settings and try again.');
              } else {
                print('[_onClickEnable] ✅ Successfully started background geolocation via native iOS permissions');
              }
              
              return; // Exit early since native permissions worked
              
            } catch (bgError) {
              print('[_onClickEnable] Error starting background geolocation with native permissions: $bgError');
              setState(() {
                _enabled = false;
              });
              _showPermissionError('Failed to start location tracking: $bgError');
              return;
            }
          }
          
          // If native permissions aren't working, try the comprehensive fix
          print('[_onClickEnable] Native permissions not working, attempting comprehensive iOS fix...');
          final iosFixResult = await IosLocationFixService.performComprehensiveFix(context: context);
          
          if (iosFixResult) {
            print('[_onClickEnable] iOS location fix successful, re-checking native permissions...');
            
            final hasNativePermissionAfterFix = await IosLocationFixService.checkNativeLocationPermission();
            final isRegisteredAfterFix = await IosLocationFixService.isAppRegisteredInSettings();
            
            if (hasNativePermissionAfterFix || isRegisteredAfterFix) {
              print('[_onClickEnable] ✅ Native iOS permissions now working after fix, starting tracking');
              
              try {
                bg.State state = await bg.BackgroundGeolocation.state;
                
                if (state.trackingMode == 1) {
                  await bg.BackgroundGeolocation.start();
                } else {
                  await bg.BackgroundGeolocation.startGeofences();
                }
                
                bg.State finalState = await bg.BackgroundGeolocation.state;
                setState(() {
                  _enabled = finalState.enabled;
                });
                
                if (finalState.enabled) {
                  print('[_onClickEnable] ✅ Successfully started background geolocation after iOS fix');
                  return; // Exit early since fix worked
                }
              } catch (bgError) {
                print('[_onClickEnable] Error starting background geolocation after iOS fix: $bgError');
              }
            }
          }
          
          print('[_onClickEnable] iOS native fixes failed, falling back to standard permission flow...');
        }
        
        // Standard permission checking for non-iOS or iOS fallback
        print('[_onClickEnable] Using standard Flutter permission checking...');
        
        // Check location permissions - prioritize "Always" over "when in use"
        final locationAlwaysStatus = await Permission.locationAlways.status;
        final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
        
        // Check motion & fitness permission (iOS)
        final motionStatus = await Permission.sensors.status;
        
        print('[_onClickEnable] Current permissions - whenInUse: $locationWhenInUseStatus, always: $locationAlwaysStatus, motion: $motionStatus');
        
        bool hasLocationPermission = false;
        bool hasAlwaysPermission = false;
        
        // Check if we have adequate location permissions
        if (locationAlwaysStatus == PermissionStatus.granted) {
          print('[_onClickEnable] ✅ Already have Always location permission - proceeding');
          hasLocationPermission = true;
          hasAlwaysPermission = true;
        } else if (locationWhenInUseStatus == PermissionStatus.granted) {
          print('[_onClickEnable] ⚠️ Have When-In-Use permission but need Always for background tracking');
          hasLocationPermission = true;
          hasAlwaysPermission = false;
        } else {
          print('[_onClickEnable] ❌ No location permission granted');
          hasLocationPermission = false;
          hasAlwaysPermission = false;
        }
        
        // If we don't have any location permission, request it first
        if (!hasLocationPermission) {
          print('[_onClickEnable] Requesting basic location permission...');
          final result = await Permission.locationWhenInUse.request();
          if (result != PermissionStatus.granted) {
            print('[_onClickEnable] Location permission denied, cannot start tracking');
            setState(() {
              _enabled = false;
            });
            _showPermissionError('Location permission is required for tracking. Please grant location permission in Settings.');
            return;
          }
          // Give iOS time to propagate the permission
          await Future.delayed(Duration(milliseconds: 1000));
          hasLocationPermission = true;
        }
        
        // If we don't have Always permission, request it
        if (!hasAlwaysPermission) {
          print('[_onClickEnable] Requesting Always location permission for background tracking...');
          final alwaysResult = await Permission.locationAlways.request();
          
          if (alwaysResult != PermissionStatus.granted) {
            print('[_onClickEnable] Always location permission denied or needs manual settings change');
            // Show dialog to guide user to settings but don't disable the switch yet
            _showAlwaysPermissionDialog();
            // Let the user decide - keep the switch on but they'll need to manually enable in settings
            return;
          } else {
            print('[_onClickEnable] ✅ Always permission granted successfully');
            hasAlwaysPermission = true;
          }
          
          // Give iOS time to propagate the permission
          await Future.delayed(Duration(milliseconds: 1000));
        }
        
        // Request motion & fitness permission if needed (not critical for tracking)
        if (motionStatus != PermissionStatus.granted) {
          print('[_onClickEnable] Requesting motion & fitness permission...');
          await Permission.sensors.request();
          // Give iOS time to propagate the permission
          await Future.delayed(Duration(milliseconds: 500));
        }
        
        print('[_onClickEnable] ✅ All required permissions ready, starting background geolocation...');
        
        // Debug the current state before starting
        await _debugBackgroundGeolocationState();
        
        // Now start background geolocation with error handling
        try {
          bg.State state = await bg.BackgroundGeolocation.state;
          print('[_onClickEnable] Current BG state before start: $state');
          
          if (state.trackingMode == 1) {
            print('[_onClickEnable] Starting background geolocation (tracking mode)...');
            await bg.BackgroundGeolocation.start();
          } else {
            print('[_onClickEnable] Starting geofences...');
            await bg.BackgroundGeolocation.startGeofences();
          }
          
          // Get the final state after starting
          bg.State finalState = await bg.BackgroundGeolocation.state;
          print('[_onClickEnable] Final BG state after start: $finalState');
          
          setState(() {
            _enabled = finalState.enabled;
          });
          
          if (!finalState.enabled) {
            print('[_onClickEnable] WARNING: Background geolocation failed to start even with permissions');
            _showPermissionError('Failed to start location tracking. Please check your location settings and try again.');
          } else {
            print('[_onClickEnable] ✅ Successfully started background geolocation');
          }
          
        } catch (bgError) {
          print('[_onClickEnable] Error starting background geolocation: $bgError');
          setState(() {
            _enabled = false;
          });
          _showPermissionError('Failed to start location tracking: $bgError');
        }
        
      } catch (e) {
        print('[_onClickEnable] Error in permission flow: $e');
        setState(() {
          _enabled = false;
        });
        _showPermissionError('Error setting up location tracking: $e');
      }
    } else {
      // Stopping tracking
      try {
        print('[_onClickEnable] Stopping background geolocation...');
        await bg.BackgroundGeolocation.stop();
        
        // Get the final state after stopping
        bg.State finalState = await bg.BackgroundGeolocation.state;
        print('[_onClickEnable] Final BG state after stop: $finalState');
        
        setState(() {
          _enabled = finalState.enabled;
        });
      } catch (e) {
        print('[_onClickEnable] Error stopping background geolocation: $e');
        // Still set to false even if there was an error stopping
        setState(() {
          _enabled = false;
        });
      }
    }
  }

  // Manually toggle the tracking state:  moving vs stationary
  /*void _onClickChangePace() {
    setState(() {
      _isMoving = !_isMoving;
    });
    print("[onClickChangePace] -> $_isMoving");

    bg.BackgroundGeolocation.changePace(_isMoving).then((bool isMoving) {
      print('[changePace] success $isMoving');
    }).catchError((e) {
      print('[changePace] ERROR: ' + e.code.toString());
    });

    if (!_isMoving) {}
  }*/

  // Manually fetch the current position.
  void _onClickGetCurrentPosition() async {
    // Skip background geolocation operations on web platform
    if (kIsWeb) {
      print('[_onClickGetCurrentPosition] Web platform detected - skipping background geolocation getCurrentPosition');
      // On web, we could use browser geolocation here if needed
      // navigator.geolocation.getCurrentPosition() would be the web equivalent
      return;
    }
    
    bg.BackgroundGeolocation.getCurrentPosition(
        persist: true,
        // <-- do not persist this location
        desiredAccuracy: 40,
        // <-- desire an accuracy of 40 meters or less
        maximumAge: 10000,
        // <-- Up to 10s old is fine.
        timeout: 30,
        // <-- wait 30s before giving up.
        samples: 3,
        // <-- sample just 1 location
        extras: {"getCurrentPosition": true}).then((bg.Location location) {
      print('[getCurrentPosition] - $location');
    }).catchError((error) {
      print('[getCurrentPosition] ERROR: $error');
    });
  }

  ////
  // Event handlers
  //

  void _onLocation(bg.Location location) {
    print('[${bg.Event.LOCATION}] - $location');

//    SendDataToAPI sender = SendDataToAPI();
//    sender.submitData(location, "location");

    setState(() {
      //_odometer = (location.odometer / 1000.0).toStringAsFixed(1);
    });
  }

  void _onLocationError(bg.LocationError error) {
    print('[${bg.Event.LOCATION}] ERROR - $error');
    setState(() {});
  }

  void _onMotionChange(bg.Location location) {
    print('[${bg.Event.MOTIONCHANGE}] - $location');
    setState(() {
      //_isMoving = location.isMoving;
    });
  }

//  void _onActivityChange(bg.ActivityChangeEvent event) {
//    print('[${bg.Event.ACTIVITYCHANGE}] - $event');
//    setState(() {
  //_motionActivity = event.activity;
//    });
//  }

  void _onProviderChange(bg.ProviderChangeEvent event) {
    print('[${bg.Event.PROVIDERCHANGE}] - $event');
    setState(() {});
  }

  void _onHttp(bg.HttpEvent event) async {
    print('[${bg.Event.HTTP}] - $event');

    setState(() {});
  }

  void _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    print('[${bg.Event.CONNECTIVITYCHANGE}] - $event');
    setState(() {});
  }

  void _onHeartbeat(bg.HeartbeatEvent event) {
    print('[${bg.Event.HEARTBEAT}] - $event');
    setState(() {});
  }

  void _onGeofence(bg.GeofenceEvent event) async {
    print('[${bg.Event.GEOFENCE}] - $event');

    bg.BackgroundGeolocation.startBackgroundTask().then((int taskId) async {
      // Execute an HTTP request to test an async operation completes.
      String url = "${ENV.TRACKER_HOST}/api/devices";
      bg.State state = await bg.BackgroundGeolocation.state;
      http.read(Uri.parse(url), headers: {
        "Authorization": "Bearer ${state.authorization!.accessToken}"
      }).then((String result) {
        print("[http test] success: $result");
        bg.BackgroundGeolocation.playSound(
            util.Dialog.getSoundId("TEST_MODE_CLICK"));
        bg.BackgroundGeolocation.stopBackgroundTask(taskId);
      }).catchError((dynamic error) {
        print("[http test] failed: $error");
        bg.BackgroundGeolocation.stopBackgroundTask(taskId);
      });
    });
  }

  void _onSchedule(bg.State state) {
    print('[${bg.Event.SCHEDULE}] - $state');
    setState(() {});
  }

  void _onEnabledChange(bool enabled) {
    print('[${bg.Event.ENABLEDCHANGE}] - $enabled');
    setState(() {
      _enabled = enabled;
    });
  }

  void _onNotificationAction(String action) {
    print('[onNotificationAction] $action');
    switch (action) {
      case 'notificationButtonFoo':
        bg.BackgroundGeolocation.changePace(false);
        break;
      case 'notificationButtonBar':
        break;
    }
  }

  void _onPowerSaveChange(bool enabled) {
    print('[${bg.Event.POWERSAVECHANGE}] - $enabled');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            appName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white, // High contrast text
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
        backgroundColor: SouthAfricanTheme.primaryBlue, // Better contrast for text and icons
        foregroundColor: SouthAfricanTheme.pureWhite,
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: SouthAfricanTheme.pureWhite,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.gps_fixed),
            color: SouthAfricanTheme.accentYellow,
            onPressed: _onClickGetCurrentPosition,
            tooltip: 'Get current location - tap to update your precise position',
          ),
          Switch(
            value: _enabled,
            onChanged: _onClickEnable,
            activeColor: SouthAfricanTheme.accentYellow,
            activeTrackColor: SouthAfricanTheme.accentYellow.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[400],
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                _enabled ? 'ON' : 'OFF',
                style: TextStyle(
                  color: SouthAfricanTheme.pureWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      //body: body,
      drawer: new WellbeingMapperSideDrawer(),
      body: MapView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/wellbeing_survey');
        },
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
        icon: Icon(Icons.add),
        label: Text('Survey'),
        tooltip: 'Take wellbeing survey - share how you feel in this location',
      ),
    );
  }

  @override
  void dispose() {
    _surveyPromptTimer?.cancel();
    super.dispose();
  }
}
