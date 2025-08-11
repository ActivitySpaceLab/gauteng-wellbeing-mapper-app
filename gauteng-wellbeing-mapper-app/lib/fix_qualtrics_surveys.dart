/// Script to fix existing Qualtrics surveys by adding questions
/// Run this from the root directory: dart lib/fix_qualtrics_surveys.dart

import 'services/qualtrics_survey_creator.dart';

Future<void> main() async {
  print('🚀 Starting Qualtrics Survey Fix...');
  
  try {
    await QualtricsSurveyCreator.fixExistingSurveys();
    print('🎉 Survey fix completed successfully!');
  } catch (e) {
    print('❌ Error during survey fix: $e');
  }
}
