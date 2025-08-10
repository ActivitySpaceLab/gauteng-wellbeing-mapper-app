import 'package:flutter/material.dart';
import 'internet_connectivity_service.dart';

class SurveyNavigationService {
  // Feature flag to control survey type (set to false to use hardcoded surveys, true for Qualtrics)
  static const bool useQualtricsSurveys = true; // TODO: Make this configurable
  
  /// Navigate to initial survey (either hardcoded or Qualtrics)
  static Future<void> navigateToInitialSurvey(BuildContext context, {String? locationJson}) async {
    if (useQualtricsSurveys) {
      print('[SurveyNavigation] Attempting Qualtrics initial survey...');
      
      // Check internet connection first
      final hasInternet = await InternetConnectivityService.hasInternetConnection();
      if (!hasInternet) {
        InternetConnectivityService.showInternetRequiredDialog(
          context,
          surveyType: 'initial',
          onRetry: () => navigateToInitialSurvey(context, locationJson: locationJson),
        );
        return;
      }
      
      Navigator.of(context).pushNamed(
        '/qualtrics_initial_survey',
        arguments: <String, String>{
          'locationHistoryJSON': locationJson ?? '',
          'locationSharingMethod': '1', // Default value
        },
      );
    } else {
      print('[SurveyNavigation] Using hardcoded initial survey...');
      Navigator.of(context).pushNamed('/initial_survey');
    }
  }
  
  /// Navigate to biweekly/recurring survey (either hardcoded or Qualtrics)
  static Future<void> navigateToBiweeklySurvey(BuildContext context, {String? locationJson}) async {
    if (useQualtricsSurveys) {
      print('[SurveyNavigation] Attempting Qualtrics biweekly survey...');
      
      // Check internet connection first
      final hasInternet = await InternetConnectivityService.hasInternetConnection();
      if (!hasInternet) {
        InternetConnectivityService.showInternetRequiredDialog(
          context,
          surveyType: 'biweekly',
          onRetry: () => navigateToBiweeklySurvey(context, locationJson: locationJson),
        );
        return;
      }
      
      // Show location sharing choice dialog for biweekly surveys
      await _showLocationSharingDialog(context, locationJson);
    } else {
      print('[SurveyNavigation] Using hardcoded biweekly survey...');
      Navigator.of(context).pushNamed('/recurring_survey');
    }
  }
  
  /// Show dialog to let user choose location sharing method
  static Future<void> _showLocationSharingDialog(BuildContext context, String? locationJson) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Location Data'),
          content: Text(
            'Would you like to share your location data from the past 2 weeks with this survey? '
            'This helps researchers understand your activity patterns.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQualtricsBiweeklySurvey(context, locationJson, '2'); // No locations
              },
              child: Text('No, Don\'t Share'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to location selection screen first, then survey
                // For now, use method '3' (selected locations)
                _navigateToQualtricsBiweeklySurvey(context, locationJson, '3');
              },
              child: Text('Choose Locations'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQualtricsBiweeklySurvey(context, locationJson, '1'); // All locations
              },
              child: Text('Share All'),
            ),
          ],
        );
      },
    );
  }
  
  /// Navigate to the actual Qualtrics biweekly survey with chosen location method
  static void _navigateToQualtricsBiweeklySurvey(BuildContext context, String? locationJson, String sharingMethod) {
    Navigator.of(context).pushNamed(
      '/qualtrics_biweekly_survey',
      arguments: <String, String>{
        'locationHistoryJSON': (sharingMethod == '2') ? '' : (locationJson ?? ''), // Empty if no sharing
        'locationSharingMethod': sharingMethod,
      },
    );
  }
  
  /// Get survey URLs for external use
  static String getInitialSurveyUrl() {
    return 'https://pretoria.eu.qualtrics.com/jfe/form/SV_byJSMxWDA88icbY';
  }
  
  static String getBiweeklySurveyUrl() {
    return 'https://pretoria.eu.qualtrics.com/jfe/form/SV_3aNJIQJXHPCyaOi';
  }
  
  /// Check if Qualtrics surveys are enabled
  static bool get isUsingQualtrics => useQualtricsSurveys;
}
