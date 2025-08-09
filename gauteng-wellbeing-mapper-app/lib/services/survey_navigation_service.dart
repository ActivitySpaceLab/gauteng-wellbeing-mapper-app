import 'package:flutter/material.dart';
import '../services/qualtrics_survey_service.dart';

class SurveyNavigationService {
  // Feature flag to control survey type (set to false to use hardcoded surveys, true for Qualtrics)
  static const bool useQualtricsSurveys = true; // TODO: Make this configurable
  
  /// Navigate to initial survey (either hardcoded or Qualtrics)
  static void navigateToInitialSurvey(BuildContext context, {String? locationJson}) {
    if (useQualtricsSurveys) {
      print('[SurveyNavigation] Attempting Qualtrics initial survey...');
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
  static void navigateToBiweeklySurvey(BuildContext context, {String? locationJson}) {
    if (useQualtricsSurveys) {
      Navigator.of(context).pushNamed(
        '/qualtrics_biweekly_survey',
        arguments: <String, String>{
          'locationHistoryJSON': locationJson ?? '',
          'locationSharingMethod': '1', // Default value
        },
      );
    } else {
      Navigator.of(context).pushNamed('/recurring_survey');
    }
  }
  
  /// Get survey URLs for external use
  static String getInitialSurveyUrl() {
    return QualtricsSurveyService.getSurveyUrl(SurveyType.initial);
  }
  
  static String getBiweeklySurveyUrl() {
    return QualtricsSurveyService.getSurveyUrl(SurveyType.biweekly);
  }
  
  /// Check if Qualtrics surveys are enabled
  static bool get isUsingQualtrics => useQualtricsSurveys;
}
