import 'package:flutter/material.dart';
import '../services/qualtrics_survey_creator.dart';

/// Utility class to help set up Qualtrics surveys
class QualtricsSurveySetup {
  
  /// Show setup instructions in a dialog
  static void showSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Qualtrics Survey Setup'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To create the three Qualtrics surveys that match your Flutter app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Get your Qualtrics API token from your Qualtrics account'),
              SizedBox(height: 8),
              Text('2. Replace YOUR_QUALTRICS_API_TOKEN_HERE in QualtricsSurveyCreator'),
              SizedBox(height: 8),
              Text('3. Tap "Create Surveys" below'),
              SizedBox(height: 8),
              Text('4. Copy the returned survey IDs to QualtricsApiService'),
              SizedBox(height: 16),
              Text(
                'This will create:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Initial Survey (demographics)'),
              Text('• Biweekly Survey (wellbeing + location)'),
              Text('• Consent Form (audit trail)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _createSurveys(context);
            },
            child: Text('Create Surveys'),
          ),
        ],
      ),
    );
  }

  /// Create the surveys and show results
  static Future<void> _createSurveys(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating surveys...'),
          ],
        ),
      ),
    );

    try {
      final surveyIds = await QualtricsSurveyCreator.createAllSurveys();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success dialog with survey IDs
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('✅ Surveys Created Successfully!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Copy these survey IDs to your QualtricsApiService:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                SelectableText('Initial Survey ID: ${surveyIds['initial']}'),
                SizedBox(height: 8),
                SelectableText('Biweekly Survey ID: ${surveyIds['biweekly']}'),
                SizedBox(height: 8),
                SelectableText('Consent Survey ID: ${surveyIds['consent']}'),
                SizedBox(height: 16),
                Text(
                  'Replace these constants in QualtricsApiService:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                SelectableText('_initialSurveyId = \'${surveyIds['initial']}\';'),
                SelectableText('_biweeklySurveyId = \'${surveyIds['biweekly']}\';'),
                SelectableText('_consentSurveyId = \'${surveyIds['consent']}\';'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('❌ Error Creating Surveys'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              SizedBox(height: 16),
              Text(
                'Make sure you have:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Valid Qualtrics API token'),
              Text('• Internet connection'),
              Text('• Qualtrics API access enabled'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Print setup instructions to console
  static void printInstructions() {
    QualtricsSurveyCreator.printSetupInstructions();
  }
}
