import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test Qualtrics API and create simple survey
void main() async {
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  
  print('🧪 Testing Qualtrics API...');
  
  try {
    // Test API connection by listing surveys
    final response = await http.get(
      Uri.parse('$baseUrl/surveys'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
    );
    
    print('API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('✅ API connection successful');
      print('Current surveys: ${result['result']['elements'].length}');
      
      // Create a simple test survey
      await createTestSurvey(baseUrl, apiToken);
      
    } else {
      print('❌ API connection failed: ${response.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> createTestSurvey(String baseUrl, String apiToken) async {
  try {
    print('\n📋 Creating test survey...');
    
    final surveyPayload = {
      'SurveyName': 'Gauteng Test Survey - Simple Text Fields',
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
    
    print('Create Survey Response: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final surveyId = result['result']['SurveyID'];
      print('✅ Test Survey created: $surveyId');
      print('🔗 Survey URL: https://pretoria.eu.qualtrics.com/jfe/form/$surveyId');
      
    } else {
      print('❌ Failed to create survey');
    }
  } catch (e) {
    print('❌ Error creating survey: $e');
  }
}
