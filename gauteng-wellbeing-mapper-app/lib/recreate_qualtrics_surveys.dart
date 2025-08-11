/// Script to recreate Qualtrics surveys with proper question format
/// Run this from the root directory: dart lib/recreate_qualtrics_surveys.dart

import 'services/qualtrics_survey_creator.dart';

Future<void> main() async {
  print('🚀 Recreating Qualtrics Surveys with proper format...');
  
  try {
    // Create surveys with simplified questions that work with Qualtrics API
    final initialSurveyId = await QualtricsSurveyCreator.createSimpleInitialSurvey();
    final biweeklySurveyId = await QualtricsSurveyCreator.createSimpleBiweeklySurvey();
    final consentSurveyId = await QualtricsSurveyCreator.createSimpleConsentSurvey();
    
    print('✅ Created surveys:');
    print('   Initial Survey: $initialSurveyId');
    print('   Biweekly Survey: $biweeklySurveyId');
    print('   Consent Survey: $consentSurveyId');
    print('🎉 Survey recreation completed successfully!');
    
  } catch (e) {
    print('❌ Error during survey recreation: $e');
  }
}
