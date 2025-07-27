import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing recurring survey notifications
/// Implements a 2-week recurring notification system that prompts users to respond to surveys
/// Now includes both in-app dialogs and device-level notifications for robustness
class NotificationService {
  static const String _lastNotificationKey = 'last_survey_notification';
  static const String _notificationCountKey = 'survey_notification_count';
  static const String _notificationTaskId = 'com.wellbeingmapper.survey_notification';
  static const String _pendingSurveyKey = 'pending_survey_prompt';
  static const int _notificationIntervalDays = 14; // 2 weeks
  
  // Device notification settings
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _scheduleNotificationTask();
    print('[NotificationService] Initialized successfully with device notifications');
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    if (_notificationsInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _notificationsInitialized = true;
    print('[NotificationService] Local notifications initialized');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('[NotificationService] Notification tapped: ${response.payload}');
    // The app will check for pending prompts when it opens
  }

  /// Schedule the background task for checking notification timing
  static Future<void> _scheduleNotificationTask() async {
    try {
      // Schedule a recurring background task to check if notification should be shown
      await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: _notificationTaskId,
        delay: 3600000, // Check every hour (in milliseconds)
        periodic: true,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiredNetworkType: NetworkType.NONE,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ));
      
      print('[NotificationService] Scheduled notification task');
    } catch (error) {
      print('[NotificationService] Error scheduling task: $error');
    }
  }

  /// Check if it's time to show a survey notification
  static Future<void> checkNotificationTiming() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final int? lastNotificationTimestamp = prefs.getInt(_lastNotificationKey);
      final DateTime now = DateTime.now();
      
      bool shouldShowNotification = false;
      
      if (lastNotificationTimestamp == null) {
        // First time - show notification after app has been used for at least a week
        final String? userUUID = prefs.getString("user_uuid");
        if (userUUID != null) {
          // User has been using the app, schedule first notification
          shouldShowNotification = true;
        }
      } else {
        final DateTime lastNotification = 
            DateTime.fromMillisecondsSinceEpoch(lastNotificationTimestamp);
        final Duration timeSinceLastNotification = now.difference(lastNotification);
        
        // Show notification if it's been 2 weeks or more
        if (timeSinceLastNotification.inDays >= _notificationIntervalDays) {
          shouldShowNotification = true;
        }
      }
      
      if (shouldShowNotification) {
        await _setPendingSurveyPrompt();
        await prefs.setInt(_lastNotificationKey, now.millisecondsSinceEpoch);
        
        // Increment notification count
        final int count = prefs.getInt(_notificationCountKey) ?? 0;
        await prefs.setInt(_notificationCountKey, count + 1);
        
        print('[NotificationService] Survey prompt scheduled. Count: ${count + 1}');
      }
    } catch (error) {
      print('[NotificationService] Error checking notification timing: $error');
    }
  }

  /// Set a flag that a survey prompt should be shown when the app opens
  /// Also shows a device notification for better visibility
  static Future<void> _setPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSurveyKey, true);
    await prefs.setInt('${_pendingSurveyKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    
    // Show device notification for better visibility
    await _showDeviceNotification();
  }

  /// Show a device-level notification
  static Future<void> _showDeviceNotification() async {
    try {
      await _initializeLocalNotifications();
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'survey_reminder_channel',
            'Survey Reminders',
            channelDescription: 'Biweekly survey participation reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        0, // notification id
        'Wellbeing Survey Reminder',
        'Help researchers by participating in your biweekly wellbeing survey! Tap to contribute to important research.',
        platformChannelSpecifics,
        payload: 'survey_reminder',
      );
      
      print('[NotificationService] Device notification shown');
    } catch (error) {
      print('[NotificationService] Error showing device notification: $error');
      // Continue without device notification - in-app dialog will still work
    }
  }

  /// Check if there's a pending survey prompt to show
  static Future<bool> hasPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingSurveyKey) ?? false;
  }

  /// Clear the pending survey prompt flag
  static Future<void> clearPendingSurveyPrompt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSurveyKey);
    await prefs.remove('${_pendingSurveyKey}_timestamp');
  }

  /// Show survey prompt dialog
  static Future<void> showSurveyPromptDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Survey Participation'),
          content: const Text(
            'Help improve research by participating in our survey! '
            'Your contributions help scientists understand human mobility patterns.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Maybe Later'),
              onPressed: () {
                Navigator.of(context).pop();
                clearPendingSurveyPrompt();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Participate'),
              onPressed: () {
                Navigator.of(context).pop();
                clearPendingSurveyPrompt();
                // Navigate to survey
                _navigateToSurvey(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Navigate to the survey webview
  static void _navigateToSurvey(BuildContext context) {
    // Navigate to the recurring survey screen
    Navigator.of(context).pushNamed('/recurring_survey');
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final int? lastNotificationTimestamp = prefs.getInt(_lastNotificationKey);
    final int notificationCount = prefs.getInt(_notificationCountKey) ?? 0;
    final bool hasPending = prefs.getBool(_pendingSurveyKey) ?? false;
    
    DateTime? lastNotificationDate;
    DateTime? nextNotificationDate;
    
    if (lastNotificationTimestamp != null) {
      lastNotificationDate = DateTime.fromMillisecondsSinceEpoch(lastNotificationTimestamp);
      nextNotificationDate = lastNotificationDate.add(Duration(days: _notificationIntervalDays));
    }
    
    return {
      'notificationCount': notificationCount,
      'lastNotificationDate': lastNotificationDate,
      'nextNotificationDate': nextNotificationDate,
      'intervalDays': _notificationIntervalDays,
      'hasPendingPrompt': hasPending,
    };
  }

  /// Reset notification schedule (for testing or user preference)
  static Future<void> resetNotificationSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationKey);
    await prefs.remove(_notificationCountKey);
    await prefs.remove(_pendingSurveyKey);
    await prefs.remove('${_pendingSurveyKey}_timestamp');
    print('[NotificationService] Notification schedule reset');
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await BackgroundFetch.stop(_notificationTaskId);
    await resetNotificationSchedule();
    print('[NotificationService] All notifications cancelled');
  }

  /// Enable notifications (for user preference)
  static Future<void> enableNotifications() async {
    await _scheduleNotificationTask();
    print('[NotificationService] Notifications enabled');
  }

  /// Disable notifications (for user preference)
  static Future<void> disableNotifications() async {
    await cancelAllNotifications();
    print('[NotificationService] Notifications disabled');
  }

  // === TESTING METHODS FOR RESEARCH TEAM ===
  
  /// Test device notification immediately (for research team testing)
  static Future<void> testDeviceNotification() async {
    await _showDeviceNotification();
    print('[NotificationService] Test device notification sent');
  }

  /// Test in-app dialog notification immediately (for research team testing)
  static Future<void> testInAppNotification(BuildContext context) async {
    await showSurveyPromptDialog(context);
    print('[NotificationService] Test in-app notification shown');
  }

  /// Test complete notification flow (device notification + in-app dialog setup)
  static Future<void> testCompleteNotificationFlow(BuildContext context) async {
    await _setPendingSurveyPrompt();
    // Also show the dialog immediately for testing
    await Future.delayed(Duration(seconds: 1));
    await showSurveyPromptDialog(context);
    print('[NotificationService] Complete notification flow tested');
  }

  /// Check notification permissions and request if needed
  static Future<bool> checkNotificationPermissions() async {
    try {
      await _initializeLocalNotifications();
      
      if (Platform.isAndroid) {
        final bool? result = await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return result ?? false;
      } else if (Platform.isIOS) {
        final bool? result = await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      }
      return true;
    } catch (error) {
      print('[NotificationService] Error checking notification permissions: $error');
      return false;
    }
  }

  /// Get detailed diagnostics for research team troubleshooting
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final stats = await getNotificationStats();
    final permissions = await checkNotificationPermissions();
    
    return {
      ...stats,
      'deviceNotificationsEnabled': permissions,
      'notificationSystemInitialized': _notificationsInitialized,
      'systemInfo': {
        'platform': Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other',
        'currentTime': DateTime.now().toIso8601String(),
      }
    };
  }
}

/// Headless task handler for notification checking
/// This runs in the background even when the app is terminated
Future<void> notificationHeadlessTask(String taskId) async {
  print('[NotificationService] Headless task executed: $taskId');
  
  if (taskId == NotificationService._notificationTaskId) {
    await NotificationService.checkNotificationTiming();
  }
  
  BackgroundFetch.finish(taskId);
}
