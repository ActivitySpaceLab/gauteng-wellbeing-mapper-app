#!/usr/bin/env dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Utility to inspect Qualtrics survey structure and get question IDs
void main() async {
  print('🔍 Inspecting Qualtrics survey structure...');
  
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const surveyId = 'SV_02r8X8ePu0b2WNw'; // Initial Survey ID
  
  await getSurveyDefinition(baseUrl, apiToken, surveyId);
  await getQuestions(baseUrl, apiToken, surveyId);
}

/// Get survey definition
Future<void> getSurveyDefinition(String baseUrl, String apiToken, String surveyId) async {
  print('\n📋 Getting survey definition...');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/surveys/$surveyId'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Accept': 'application/json',
      },
    );

    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Survey definition: ${jsonEncode(data)}');
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Network error: $e');
  }
}

/// Get survey questions
Future<void> getQuestions(String baseUrl, String apiToken, String surveyId) async {
  print('\n❓ Getting survey questions...');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/surveys/$surveyId/questions'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Accept': 'application/json',
      },
    );

    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Questions: ${jsonEncode(data)}');
      
      // Try to extract question IDs
      if (data['result'] != null && data['result']['elements'] != null) {
        final elements = data['result']['elements'] as List;
        print('\n📝 Question IDs found:');
        for (var element in elements) {
          if (element['QuestionID'] != null) {
            print('  - ${element['QuestionID']}: ${element['QuestionText'] ?? 'Unknown'}');
          }
        }
      }
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Network error: $e');
  }
}
