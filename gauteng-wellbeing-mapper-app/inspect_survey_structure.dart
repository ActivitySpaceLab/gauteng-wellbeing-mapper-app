/// Inspect Qualtrics survey structure to identify required fields
import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
const String apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
const String initialSurveyId = 'SV_bsb8iq0UiATXRJQ';

Future<void> main() async {
  print('🔍 Inspecting Survey Structure for Required Fields...');
  print('=====================================================\n');
  
  // Get survey questions
  await getSurveyQuestions();
}

Future<void> getSurveyQuestions() async {
  print('📋 Getting survey questions...');
  
  final response = await http.get(
    Uri.parse('$baseUrl/surveys/$initialSurveyId/questions'),
    headers: {
      'X-API-TOKEN': apiToken,
      'Content-Type': 'application/json',
    },
  );
  
  print('📥 Questions API Status: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final questionsData = jsonDecode(response.body);
    final questions = questionsData['result']['elements'] as List;
    
    print('🔍 Found ${questions.length} questions:');
    print('=' * 60);
    
    for (final question in questions) {
      final questionId = question['questionID'];
      final questionText = question['questionText'] ?? 'No text';
      final validation = question['validation'];
      final questionType = question['questionType'];
      
      // Check if question is required
      bool isRequired = false;
      if (validation != null && validation['settings'] != null) {
        isRequired = validation['settings']['forceResponse'] == true ||
                     validation['settings']['doesForceResponse'] == true;
      }
      
      print('🎯 Question ID: $questionId');
      print('   Type: $questionType');
      print('   Required: ${isRequired ? "YES" : "No"}');
      print('   Text: ${questionText.replaceAll(RegExp(r'<[^>]*>'), '').trim()}');
      
      if (isRequired) {
        print('   ⚠️  THIS FIELD IS REQUIRED FOR API SUBMISSION!');
      }
      
      print('   ---');
    }
    
    // Also get survey options/response requirements
    await getSurveyOptions();
    
  } else {
    print('❌ Error getting questions: ${response.body}');
  }
}

Future<void> getSurveyOptions() async {
  print('\n📋 Getting survey response options...');
  
  final response = await http.get(
    Uri.parse('$baseUrl/surveys/$initialSurveyId/options'),
    headers: {
      'X-API-TOKEN': apiToken,
      'Content-Type': 'application/json',
    },
  );
  
  print('📥 Options API Status: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final optionsData = jsonDecode(response.body);
    print('📋 Survey Options:');
    print(jsonEncode(optionsData['result']));
  } else {
    print('❌ Error getting options: ${response.body}');
  }
}
