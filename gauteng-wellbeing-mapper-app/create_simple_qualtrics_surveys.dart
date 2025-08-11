import 'dart:convert';
import 'package:http/http.dart' as http;

/// Create simple Qualtrics surveys using text fields for fast, reliable data collection
void main() async {
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  
  print('🚀 Creating simple Qualtrics surveys with text fields...');
  
  // Create Initial Survey
  await createInitialSurvey(baseUrl, apiToken);
  
  // Create Biweekly Survey
  await createBiweeklySurvey(baseUrl, apiToken);
  
  // Create Consent Survey
  await createConsentSurvey(baseUrl, apiToken);
}

Future<void> createInitialSurvey(String baseUrl, String apiToken) async {
  try {
    print('\n📋 Creating Initial Survey...');
    
    final surveyPayload = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Initial Survey (Simple)',
      'Language': 'EN',
      'ProjectCategory': 'CORE'
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/survey-definitions'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(surveyPayload),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final surveyId = result['result']['SurveyID'];
      print('✅ Initial Survey created: $surveyId');
      
      // Add questions as text fields
      await addInitialSurveyQuestions(baseUrl, apiToken, surveyId);
      
      // Publish survey
      await publishSurvey(baseUrl, apiToken, surveyId);
      
    } else {
      print('❌ Failed to create initial survey: ${response.body}');
    }
  } catch (e) {
    print('❌ Error creating initial survey: $e');
  }
}

Future<void> addInitialSurveyQuestions(String baseUrl, String apiToken, String surveyId) async {
  final questions = [
    // Participant identifiers
    {'text': 'Participant UUID (hidden)', 'type': 'TE'},
    {'text': 'Participant Code', 'type': 'TE'},
    
    // Wave 1 only questions
    {'text': 'Age', 'type': 'TE'},
    {'text': 'Suburb or community in Gauteng', 'type': 'TE'},
    {'text': 'Race/ethnicity', 'type': 'TE'},
    {'text': 'Gender identity', 'type': 'TE'},
    {'text': 'Sexual orientation', 'type': 'TE'},
    {'text': 'Place of birth', 'type': 'TE'},
    {'text': 'Building type', 'type': 'TE'},
    {'text': 'Household items (comma-separated)', 'type': 'TE'},
    {'text': 'Education level', 'type': 'TE'},
    {'text': 'Climate activism involvement', 'type': 'TE'},
    
    // All waves questions
    {'text': 'Activities in last two weeks (comma-separated)', 'type': 'TE'},
    {'text': 'Living arrangement (alone/with others)', 'type': 'TE'},
    {'text': 'Relationship status', 'type': 'TE'},
    {'text': 'General health (1-5)', 'type': 'TE'},
    {'text': 'Cheerful spirits (0-5)', 'type': 'TE'},
    {'text': 'Calm and relaxed (0-5)', 'type': 'TE'},
    {'text': 'Active and vigorous (0-5)', 'type': 'TE'},
    {'text': 'Woke up fresh and rested (0-5)', 'type': 'TE'},
    {'text': 'Daily life filled with interesting things (0-5)', 'type': 'TE'},
    {'text': 'I cooperate with people (1-5)', 'type': 'TE'},
    {'text': 'Improving qualifications/skills important (1-5)', 'type': 'TE'},
    {'text': 'Know how to behave in social situations (1-5)', 'type': 'TE'},
    {'text': 'Family have supported me (1-5)', 'type': 'TE'},
    
    // Location and metadata
    {'text': 'Encrypted location data (hidden)', 'type': 'TE'},
    {'text': 'Submission timestamp (hidden)', 'type': 'TE'},
  ];
  
  for (int i = 0; i < questions.length; i++) {
    await addQuestion(baseUrl, apiToken, surveyId, questions[i], i + 1);
  }
}

Future<void> createBiweeklySurvey(String baseUrl, String apiToken) async {
  try {
    print('\n📋 Creating Biweekly Survey...');
    
    final surveyPayload = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Biweekly Survey (Simple)',
      'Language': 'EN',
      'ProjectCategory': 'CORE'
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/survey-definitions'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(surveyPayload),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final surveyId = result['result']['SurveyID'];
      print('✅ Biweekly Survey created: $surveyId');
      
      // Add questions as text fields
      await addBiweeklySurveyQuestions(baseUrl, apiToken, surveyId);
      
      // Publish survey
      await publishSurvey(baseUrl, apiToken, surveyId);
      
    } else {
      print('❌ Failed to create biweekly survey: ${response.body}');
    }
  } catch (e) {
    print('❌ Error creating biweekly survey: $e');
  }
}

Future<void> addBiweeklySurveyQuestions(String baseUrl, String apiToken, String surveyId) async {
  final questions = [
    // Participant identifiers
    {'text': 'Participant UUID (hidden)', 'type': 'TE'},
    
    // All waves questions only (no Wave 1 demographics)
    {'text': 'Activities in last two weeks (comma-separated)', 'type': 'TE'},
    {'text': 'Living arrangement (alone/with others)', 'type': 'TE'},
    {'text': 'Relationship status', 'type': 'TE'},
    {'text': 'General health (1-5)', 'type': 'TE'},
    {'text': 'Cheerful spirits (0-5)', 'type': 'TE'},
    {'text': 'Calm and relaxed (0-5)', 'type': 'TE'},
    {'text': 'Active and vigorous (0-5)', 'type': 'TE'},
    {'text': 'Woke up fresh and rested (0-5)', 'type': 'TE'},
    {'text': 'Daily life filled with interesting things (0-5)', 'type': 'TE'},
    {'text': 'I cooperate with people (1-5)', 'type': 'TE'},
    {'text': 'Improving qualifications/skills important (1-5)', 'type': 'TE'},
    {'text': 'Know how to behave in social situations (1-5)', 'type': 'TE'},
    {'text': 'Family have supported me (1-5)', 'type': 'TE'},
    
    // Environmental challenges and coping
    {'text': 'Environmental challenges experienced', 'type': 'TE'},
    {'text': 'Stress level from challenges (1-5)', 'type': 'TE'},
    {'text': 'What helped cope with challenges', 'type': 'TE'},
    
    // Location and metadata
    {'text': 'Encrypted location data (hidden)', 'type': 'TE'},
    {'text': 'Submission timestamp (hidden)', 'type': 'TE'},
  ];
  
  for (int i = 0; i < questions.length; i++) {
    await addQuestion(baseUrl, apiToken, surveyId, questions[i], i + 1);
  }
}

Future<void> createConsentSurvey(String baseUrl, String apiToken) async {
  try {
    print('\n📋 Creating Consent Survey...');
    
    final surveyPayload = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Consent Form (Simple)',
      'Language': 'EN',
      'ProjectCategory': 'CORE'
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/survey-definitions'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(surveyPayload),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final surveyId = result['result']['SurveyID'];
      print('✅ Consent Survey created: $surveyId');
      
      // Add questions as text fields
      await addConsentSurveyQuestions(baseUrl, apiToken, surveyId);
      
      // Publish survey
      await publishSurvey(baseUrl, apiToken, surveyId);
      
    } else {
      print('❌ Failed to create consent survey: ${response.body}');
    }
  } catch (e) {
    print('❌ Error creating consent survey: $e');
  }
}

Future<void> addConsentSurveyQuestions(String baseUrl, String apiToken, String surveyId) async {
  final questions = [
    {'text': 'Participant Code', 'type': 'TE'},
    {'text': 'Participant UUID', 'type': 'TE'},
    {'text': 'Informed consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Data processing consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Location data consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Survey data consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Data retention consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Data sharing consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Voluntary participation consent (1=yes, 0=no)', 'type': 'TE'},
    {'text': 'Participant signature', 'type': 'TE'},
    {'text': 'Consent timestamp', 'type': 'TE'},
  ];
  
  for (int i = 0; i < questions.length; i++) {
    await addQuestion(baseUrl, apiToken, surveyId, questions[i], i + 1);
  }
}

Future<void> addQuestion(String baseUrl, String apiToken, String surveyId, Map<String, String> question, int questionNumber) async {
  try {
    final questionPayload = {
      'QuestionText': question['text'],
      'QuestionType': question['type'],
      'DataExportTag': 'Q$questionNumber',
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/survey-definitions/$surveyId/questions'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(questionPayload),
    );
    
    if (response.statusCode == 200) {
      print('  ✅ Added Q$questionNumber: ${question['text']}');
    } else {
      print('  ❌ Failed to add Q$questionNumber: ${response.body}');
    }
  } catch (e) {
    print('  ❌ Error adding question: $e');
  }
}

Future<void> publishSurvey(String baseUrl, String apiToken, String surveyId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/survey-definitions/$surveyId/publish'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      print('  ✅ Survey published successfully');
      print('  🔗 Survey URL: https://pretoria.eu.qualtrics.com/jfe/form/$surveyId');
    } else {
      print('  ❌ Failed to publish survey: ${response.body}');
    }
  } catch (e) {
    print('  ❌ Error publishing survey: $e');
  }
}
