import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Testing Fixed Qualtrics API Format ===\n');
  
  const String qualtricsToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const String qualtricsUrl = 'https://pretoria.eu.qualtrics.com';
  const String surveyId = 'SV_8pudN8qTI6iQKY6'; // Initial survey
  
  // Test with the corrected format (simple values wrapper)
  final testData = {
    'values': {
      'QID1': 'TEST-UUID-FIXED-${DateTime.now().millisecondsSinceEpoch}',
      'QID2': 'TEST-CODE-FIXED-${DateTime.now().millisecondsSinceEpoch}',
      'QID3': '28',
      'QID4': 'Cape Town',
      'QID5': 'Coloured',
      'QID6': '5', // Very happy
      'QID7': '4', // Agree
    },
    'recordedDate': DateTime.now().toIso8601String(),
  };
  
  print('Submitting test data with corrected format...');
  print('Data: ${jsonEncode(testData)}');
  print('');
  
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/surveys/$surveyId/responses'));
    request.headers.set('X-API-TOKEN', qualtricsToken);
    request.headers.set('Content-Type', 'application/json');
    
    request.write(jsonEncode(testData));
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    print('Submission Status: ${response.statusCode}');
    print('Response: $responseBody');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      final responseId = responseData['result']['responseId'];
      print('✅ Response ID: $responseId');
      
      // Wait a moment and check if data appears
      print('\\nWaiting 3 seconds then checking data visibility...');
      await Future.delayed(Duration(seconds: 3));
      
      final checkRequest = await client.getUrl(Uri.parse('$qualtricsUrl/API/v3/surveys/$surveyId/responses/$responseId'));
      checkRequest.headers.set('X-API-TOKEN', qualtricsToken);
      checkRequest.headers.set('Content-Type', 'application/json');
      
      final checkResponse = await checkRequest.close();
      final checkBody = await checkResponse.transform(utf8.decoder).join();
      
      print('Data Retrieval Status: ${checkResponse.statusCode}');
      
      if (checkResponse.statusCode == 200) {
        final checkData = jsonDecode(checkBody);
        final values = checkData['result']['values'];
        
        print('\\n=== DATA VISIBILITY CHECK ===');
        print('Fields with data:');
        
        int dataFieldCount = 0;
        for (var entry in values.entries) {
          if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
            dataFieldCount++;
            // Only show our test fields
            if (entry.key.startsWith('QID')) {
              print('  ${entry.key}: "${entry.value}"');
            }
          }
        }
        
        if (dataFieldCount > 5) { // More than just metadata
          print('\\n✅ SUCCESS: Data is visible in Qualtrics!');
          print('The fix worked - survey data now appears correctly.');
        } else {
          print('\\n❌ Data still not visible - only metadata fields present');
        }
      } else {
        print('❌ Failed to retrieve response for verification');
      }
    } else {
      print('❌ Submission failed');
    }
    
    client.close();
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\\n=== Test Complete ===');
}
