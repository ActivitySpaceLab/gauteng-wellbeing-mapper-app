import 'lib/services/qualtrics_survey_creator.dart';

void main() async {
  print('🚀 Creating Qualtrics surveys...');
  try {
    final surveyIds = await QualtricsSurveyCreator.createAllSurveys();
    print('');
    print('✅ SUCCESS! Surveys created successfully:');
    print('');
    print('📋 INITIAL SURVEY ID: ${surveyIds['initial']}');
    print('🔄 BIWEEKLY SURVEY ID: ${surveyIds['biweekly']}');
    print('📝 CONSENT SURVEY ID: ${surveyIds['consent']}');
    print('');
    print('🔧 Next steps:');
    print('1. Copy these IDs to your QualtricsApiService constants');
    print('2. Update the following lines in lib/services/qualtrics_api_service.dart:');
    print('   static const String _initialSurveyId = \'${surveyIds['initial']}\';');
    print('   static const String _biweeklySurveyId = \'${surveyIds['biweekly']}\';');
    print('   static const String _consentSurveyId = \'${surveyIds['consent']}\';');
  } catch (e) {
    print('❌ Error creating surveys: $e');
    print('');
    print('Troubleshooting:');
    print('- Check your Qualtrics API token is valid');
    print('- Ensure you have internet connection');
    print('- Verify your Qualtrics account has API access enabled');
  }
}
