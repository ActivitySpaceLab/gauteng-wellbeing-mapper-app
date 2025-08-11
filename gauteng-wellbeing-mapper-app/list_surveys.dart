import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class QualtricsAPILister {
  static const String _baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  static const String _apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';

  Future<void> listSurveys() async {
    final url = Uri.parse('$_baseUrl/surveys');
    
    print('📋 Fetching all surveys...');
    
    final response = await http.get(
      url,
      headers: {
        'X-API-TOKEN': _apiToken,
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final surveys = responseJson['result']['elements'] as List;
      
      print('\n🔍 Found ${surveys.length} surveys:');
      print('=' * 80);
      
      for (final survey in surveys) {
        final name = survey['name'] ?? 'Unnamed Survey';
        final id = survey['id'] ?? 'No ID';
        final isActive = survey['isActive'] ?? false;
        final lastModified = survey['lastModified'] ?? 'Unknown';
        
        // Look for our specific surveys
        if (name.contains('Gauteng Wellbeing Mapper')) {
          print('🎯 FOUND TARGET SURVEY:');
          print('   Name: $name');
          print('   ID: $id');
          print('   Active: $isActive');
          print('   Last Modified: $lastModified');
          print('   ---');
        }
      }
      
      // Also show all surveys for reference
      print('\n📝 All surveys:');
      for (final survey in surveys) {
        final name = survey['name'] ?? 'Unnamed Survey';
        final id = survey['id'] ?? 'No ID';
        print('  • $name (ID: $id)');
      }
      
    } else {
      throw Exception('Failed to list surveys: ${response.statusCode} ${response.body}');
    }
  }
}

void main() async {
  try {
    final lister = QualtricsAPILister();
    await lister.listSurveys();
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
