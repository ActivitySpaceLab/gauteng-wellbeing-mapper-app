import 'lib/services/qualtrics_survey_creator.dart';

/// Script to update the consent survey with all consent questions
Future<void> main() async {
  print('🚀 Starting consent survey update...');
  
  try {
    await QualtricsSurveyCreator.updateConsentSurveyQuestions();
    print('🎉 Consent survey update completed successfully!');
  } catch (e) {
    print('❌ Error updating consent survey: $e');
  }
}
