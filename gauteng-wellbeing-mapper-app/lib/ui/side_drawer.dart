import 'dart:convert';
import 'package:wellbeing_mapper/main.dart';
import 'package:wellbeing_mapper/models/app_localizations.dart';
import 'package:wellbeing_mapper/models/custom_locations.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/wellbeing_survey_service.dart';
import 'package:wellbeing_mapper/services/initial_survey_service.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';
import 'package:wellbeing_mapper/debug/ios_location_debug.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class WellbeingMapperSideDrawer extends StatefulWidget {
  @override
  _WellbeingMapperSideDrawerState createState() => _WellbeingMapperSideDrawerState();
}

class _WellbeingMapperSideDrawerState extends State<WellbeingMapperSideDrawer> {
  AppMode currentMode = AppMode.private; // Default to private mode
  bool isLoading = true;
  bool hasCompletedInitialSurvey = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
    _checkInitialSurveyStatus();
  }

  Future<void> _loadCurrentMode() async {
    try {
      final mode = await AppModeService.getCurrentMode();
      setState(() {
        currentMode = mode;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading current mode: $e');
      setState(() {
        currentMode = AppMode.private; // Default to private on error
        isLoading = false;
      });
    }
  }

  Future<void> _checkInitialSurveyStatus() async {
    try {
      final completed = await InitialSurveyService.hasCompletedInitialSurvey();
      setState(() {
        hasCompletedInitialSurvey = completed;
      });
    } catch (e) {
      print('Error checking initial survey status: $e');
    }
  }

  void _navigateToChangeMode() async {
    await Navigator.of(context).pushNamed('/change_mode');
    // Refresh current mode and survey status when returning from change mode
    _loadCurrentMode();
    _checkInitialSurveyStatus();
  }

  Future<void> _exportData() async {
    try {
      print('[SideDrawer] Starting data export...');
      var now = DateTime.now();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Preparing data export..."),
              ],
            ),
          );
        },
      );

      // Get location data - skip background geolocation on web platform
      List allLocations = [];
      List<ShareLocation> customLocation = [];
      
      if (kIsWeb) {
        print('[SideDrawer] Web platform detected - skipping background geolocation data export');
        // On web, we could potentially get location data from other sources
        // For now, export empty location list
      } else {
        try {
          allLocations = await bg.BackgroundGeolocation.locations;
          print('[SideDrawer] Retrieved ${allLocations.length} location records');
          
          // Convert to custom location format
          for (var thisLocation in allLocations) {
            final bgLocation = bg.Location(thisLocation);
            ShareLocation _loc = ShareLocation(
                bgLocation.timestamp,
                bgLocation.coords.latitude,
                bgLocation.coords.longitude,
                bgLocation.coords.accuracy,
                GlobalData.userUUID);
            customLocation.add(_loc);
          }
        } catch (e) {
          print('[SideDrawer] Error getting location data: $e');
          // Continue with empty location list
        }
      }

      // Get wellbeing survey data
      List wellbeingSurveys = [];
      try {
        final surveys = await WellbeingSurveyService().getWellbeingSurveysForExport();
        wellbeingSurveys = surveys.map((survey) => survey.toJson()).toList();
        print('[SideDrawer] Retrieved ${wellbeingSurveys.length} wellbeing surveys');
      } catch (e) {
        print('[SideDrawer] Error getting wellbeing surveys for export: $e');
        // Continue with empty survey list
      }

      // Get initial survey data if available
      Map<String, dynamic>? initialSurveyData;
      try {
        final hasCompleted = await InitialSurveyService.hasCompletedInitialSurvey();
        if (hasCompleted) {
          // Try to get initial survey data if available
          initialSurveyData = {
            'completed': true,
            'completion_date': 'Available in database',
            'note': 'Initial survey data can be retrieved from local database'
          };
        }
      } catch (e) {
        print('[SideDrawer] Error getting initial survey data: $e');
      }

      // Create comprehensive export data
      Map<String, dynamic> exportData = {
        'export_info': {
          'timestamp': now.toIso8601String(),
          'app_version': '0.1.11+1',
          'export_format_version': '1.0',
          'app_mode': currentMode.displayName,
          'user_id': GlobalData.userUUID,
        },
        'data_summary': {
          'location_records': customLocation.length,
          'wellbeing_surveys': wellbeingSurveys.length,
          'initial_survey_completed': hasCompletedInitialSurvey,
          'export_date_range': customLocation.isNotEmpty 
            ? {
                'total_location_records': customLocation.length,
                'note': 'Location data available - see location_data section for details',
              }
            : {
                'total_location_records': 0,
                'note': 'No location data available',
              },
        },
        'location_data': customLocation.map((loc) => loc.toJson()).toList(),
        'wellbeing_surveys': wellbeingSurveys,
        'initial_survey': initialSurveyData,
        'privacy_note': currentMode == AppMode.private 
          ? 'This data was collected in Private Mode - no data has been shared with research servers.'
          : currentMode == AppMode.appTesting
            ? 'This data was collected in App Testing Mode - data is stored locally for testing purposes only.'
            : 'This data was collected in Research Mode - data may have been shared with research servers based on your consent preferences.',
      };

      // Close loading dialog
      Navigator.of(context).pop();

      // Format the JSON nicely
      String prettyString = JsonEncoder.withIndent('  ').convert(exportData);
      
      // Show export options dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Export Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Location records: ${customLocation.length}'),
                Text('• Wellbeing surveys: ${wellbeingSurveys.length}'),
                Text('• Initial survey: ${hasCompletedInitialSurvey ? "Completed" : "Not completed"}'),
                Text('• App mode: ${currentMode.displayName}'),
                SizedBox(height: 16),
                Text('This will share your data as formatted JSON text that you can save or share as needed.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Share.share(
                    prettyString,
                    subject: 'Wellbeing Mapper Data Export - ${now.toIso8601String().split('T')[0]}',
                  );
                },
                child: Text('Export Data'),
              ),
            ],
          );
        },
      );
      
      print('[SideDrawer] Data export completed successfully');
      
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context, rootNavigator: true).pop();
      
      print('[SideDrawer] Error during data export: $e');
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Export Error'),
            content: Text('Sorry, there was an error preparing your data for export. Please try again.\n\nError: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  _launchProjectURL() async {
    final Uri url = Uri.parse('https://planet4health.eu/mental-wellbeing-in-environmental-climate-context/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 100,
            child: DrawerHeader(
              child: Text(
                  AppLocalizations.of(context)
                          ?.translate("side_drawer_title") ??
                      "",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              decoration: BoxDecoration(
                color: Colors.blueGrey[200],
              ),
            ),
          ),
          if (isLoading)
            Card(
              child: ListTile(
                leading: const Icon(Icons.refresh),
                title: Text("Loading..."),
              ),
            )
          else ...[
            // App Mode - Always visible (moved to first position)
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text("App Mode"),
                subtitle: Text(currentMode.displayName),
                trailing: Text("Change Mode", style: TextStyle(color: SouthAfricanTheme.primaryBlue)),
                onTap: () {
                  _navigateToChangeMode();
                },
              ),
            ),
            // Wellbeing Map - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text("Wellbeing Map"),
                subtitle: Text("View your wellbeing responses on map"),
                onTap: () {
                  Navigator.of(context).pushNamed('/wellbeing_map');
                },
              ),
            ),
            // Wellbeing Timeline - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.timeline),
                title: Text("Wellbeing Timeline"),
                subtitle: Text("Track your wellbeing trends over time"),
                onTap: () {
                  Navigator.of(context).pushNamed('/wellbeing_timeline');
                },
              ),
            ),
            // Research and App Testing mode menu items
            if (currentMode != AppMode.private) ...[
              Card(
                child: ListTile(
                  leading: Icon(
                    hasCompletedInitialSurvey ? Icons.assignment_turned_in : Icons.assignment,
                    color: hasCompletedInitialSurvey ? Colors.green : null,
                  ),
                  title: Text("Initial Survey"),
                  subtitle: Text(hasCompletedInitialSurvey 
                    ? "Completed ✓" 
                    : "Complete your initial demographics survey"
                  ),
                  trailing: hasCompletedInitialSurvey 
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.warning, color: Colors.orange),
                  onTap: () async {
                    final result = await Navigator.of(context).pushNamed('/initial_survey');
                    // Refresh status when returning
                    if (result == true) {
                      await InitialSurveyService.markInitialSurveyCompleted();
                      _checkInitialSurveyStatus();
                    }
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: Text("Wellbeing Survey"),
                  subtitle: Text("Bi-weekly wellbeing check-in"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/recurring_survey');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text("Survey History"),
                  subtitle: Text("View completed surveys"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/survey_list');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text("Survey Notifications"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/notification_settings');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: Text("Research Data Upload"),
                  subtitle: Text("Upload encrypted data to research servers"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/data_upload');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text("Data Sharing Preferences"),
                  subtitle: Text("Manage your data sharing consent choices"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/data_sharing_preferences');
                  },
                ),
              ),
            ],
            // Export Data - Always visible (renamed from Share Locations)
            Card(
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text("Export Data"),
                onTap: () {
                  _exportData();
                },
              ),
            ),
            // iOS Location Debug - Debug tool for diagnosing iOS location permission issues
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: Text("iOS Location Debug"),
                subtitle: Text("Diagnose location permission issues"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => IosLocationDebugScreen(),
                    ),
                  );
                },
              ),
            ),
            // Help & Guide - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.help),
                title: Text("Help & Guide"),
                subtitle: Text("Learn how to use the app"),
                onTap: () {
                  Navigator.of(context).pushNamed('/help');
                },
              ),
            ),
            // Visit Project Website - Second to last
            Card(
              child: ListTile(
                leading: const Icon(Icons.web),
                title: Text(AppLocalizations.of(context)
                        ?.translate("visit_project_website") ??
                    ""),
                onTap: () {
                  _launchProjectURL();
                },
              ),
            ),
            // Report an Issue - Last
            Card(
              child: ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: Text(
                    AppLocalizations.of(context)?.translate("report_an_issue") ??
                        ""),
                onTap: () {
                  Navigator.of(context).pushNamed('/report_an_issue');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
