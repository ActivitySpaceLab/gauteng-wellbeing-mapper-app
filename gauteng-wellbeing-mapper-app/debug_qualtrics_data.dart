import 'dart:convert';
import 'package:http/http.dart' as http;

/// Debug test to see exactly what data is being sent to Qualtrics
void main() async {
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  
  print('🔍 DEBUG: Testing Qualtrics Data Submission');
  print('============================================');
  
  // Test with a minimal dataset first
  final testData = {
    'QID1': 'test-participant-uuid-debug-123',
    'QID2': '28',
    'QID3': 'Pretoria',
    'QID4': 'Black',
    'QID5': 'Female',
  };
  
  print('\n📤 Sending data to Initial Survey:');
  testData.forEach((key, value) {
    print('   $key: $value');
  });
  
  try {
    final surveyId = 'SV_8pudN8qTI6iQKY6';
    final response = await http.post(
      Uri.parse('$baseUrl/surveys/$surveyId/responses'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'values': testData,
      }),
    );
    
    print('\n📥 Response:');
    print('   Status: ${response.statusCode}');
    print('   Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('   ✅ Response ID: ${responseData['result']['id']}');
      
      // Now let's check if we can retrieve this response
      if (responseData['result']['id'] != null) {
        await checkResponse(baseUrl, apiToken, surveyId, responseData['result']['id']);
      }
    }
  } catch (e) {
    print('   ❌ ERROR: $e');
  }
}

Future<void> checkResponse(String baseUrl, String apiToken, String surveyId, String responseId) async {
  try {
    print('\n🔍 Checking submitted response...');
    final response = await http.get(
      Uri.parse('$baseUrl/surveys/$surveyId/responses/$responseId'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
    );
    
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('   Retrieved data: ${responseData['result']['values']}');
    } else {
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('   ❌ ERROR: $e');
  }
}
