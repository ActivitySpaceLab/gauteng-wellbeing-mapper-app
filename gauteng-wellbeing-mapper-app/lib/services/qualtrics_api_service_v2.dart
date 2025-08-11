import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // For GlobalData
import '../db/survey_database.dart';

/// Service for syncing local survey data with Qualtrics via API
class QualtricsApiService {
  // TODO: Replace with your actual Qualtrics API credentials
  static const String _baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  static const String _apiToken = 'YOUR_QUALTRICS_API_TOKEN_HERE';
  
  // Your survey IDs from Qualtrics
  static const String _initialSurveyId = 'SV_bsb8iq0UiATXRJQ';
  static const String _biweeklySurveyId = 'SV_eUJstaSWQeKykBM';
  
  /// Sync a completed initial survey to Qualtrics
  static Future<bool> syncInitialSurvey(Map<String, dynamic> surveyData) async {
    try {
      final responseData = _mapInitialSurveyToQualtrics(surveyData);
      
      final success = await _createSurveyResponse(
        _initialSurveyId, 
        responseData,
        DateTime.parse(surveyData['submitted_at'] as String),
      );
      
      if (success) {
        debugPrint('✅ Initial survey synced to Qualtrics successfully');
        // Mark as synced in local database
        final db = SurveyDatabase();
        await db.markInitialSurveySynced(surveyData['id'] as int);
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to sync initial survey: $e');
      return false;
    }
  }

  /// Sync a completed biweekly survey to Qualtrics
  static Future<bool> syncBiweeklySurvey(Map<String, dynamic> surveyData) async {
    try {
      final responseData = _mapBiweeklySurveyToQualtrics(surveyData);
      
      final success = await _createSurveyResponse(
        _biweeklySurveyId, 
        responseData,
        DateTime.parse(surveyData['submitted_at'] as String),
      );
      
      if (success) {
        debugPrint('✅ Biweekly survey synced to Qualtrics successfully');
        // Mark as synced in local database
        final db = SurveyDatabase();
        await db.markRecurringSurveySynced(surveyData['id'] as int);
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to sync biweekly survey: $e');
      return false;
    }
  }

  /// Sync all pending surveys to Qualtrics
  static Future<void> syncPendingSurveys() async {
    try {
      final db = SurveyDatabase();
      
      // Sync pending initial surveys
      final pendingInitial = await db.getUnsyncedInitialSurveys();
      for (final survey in pendingInitial) {
        await syncInitialSurvey(survey);
        // Add small delay to avoid API rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Sync pending biweekly surveys  
      final pendingBiweekly = await db.getUnsyncedRecurringSurveys();
      for (final survey in pendingBiweekly) {
        await syncBiweeklySurvey(survey);
        // Add small delay to avoid API rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      debugPrint('🔄 Completed sync of all pending surveys');
    } catch (e) {
      debugPrint('❌ Error during bulk sync: $e');
    }
  }

  /// Create a survey response in Qualtrics
  static Future<bool> _createSurveyResponse(
    String surveyId, 
    Map<String, dynamic> responseData,
    DateTime submittedAt,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/surveys/$surveyId/responses');
      
      final requestBody = {
        'values': responseData,
        'finished': true,
        'recordedDate': submittedAt.toUtc().toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {
          'X-API-TOKEN': _apiToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        final responseId = responseJson['result']['id'];
        debugPrint('✅ Survey response created with ID: $responseId');
        return true;
      } else {
        debugPrint('❌ Qualtrics API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Network error creating survey response: $e');
      return false;
    }
  }

  /// Map initial survey data to Qualtrics format
  static Map<String, dynamic> _mapInitialSurveyToQualtrics(Map<String, dynamic> survey) {
    final data = <String, dynamic>{};
    
    // Add participant UUID from global data
    data['QID1'] = GlobalData.userUUID;
    
    // Map survey fields to Qualtrics question IDs
    if (survey['age'] != null) data['QID2'] = survey['age'].toString();
    if (survey['ethnicity'] != null) {
      final ethnicity = jsonDecode(survey['ethnicity'] as String) as List;
      data['QID3'] = ethnicity.join(',');
    }
    if (survey['gender'] != null) data['QID4'] = survey['gender'];
    if (survey['sexuality'] != null) data['QID5'] = survey['sexuality'];
    if (survey['birth_place'] != null) data['QID6'] = survey['birth_place'];
    if (survey['lives_in_barcelona'] != null) data['QID7'] = survey['lives_in_barcelona'];
    if (survey['building_type'] != null) data['QID8'] = survey['building_type'];
    if (survey['household_items'] != null) {
      final items = jsonDecode(survey['household_items'] as String) as List;
      data['QID9'] = items.join(',');
    }
    if (survey['education'] != null) data['QID10'] = survey['education'];
    if (survey['climate_activism'] != null) data['QID11'] = survey['climate_activism'];
    if (survey['general_health'] != null) data['QID12'] = survey['general_health'];
    
    return data;
  }

  /// Map biweekly survey data to Qualtrics format
  static Map<String, dynamic> _mapBiweeklySurveyToQualtrics(Map<String, dynamic> survey) {
    final data = <String, dynamic>{};
    
    // Add participant UUID
    data['QID1'] = GlobalData.userUUID;
    
    // Map survey fields to Qualtrics question IDs
    if (survey['activities'] != null) {
      final activities = jsonDecode(survey['activities'] as String) as List;
      data['QID2'] = activities.join(',');
    }
    if (survey['living_arrangement'] != null) data['QID3'] = survey['living_arrangement'];
    if (survey['relationship_status'] != null) data['QID4'] = survey['relationship_status'];
    if (survey['general_health'] != null) data['QID5'] = survey['general_health'];
    
    // Wellbeing questions (0-5 scale)
    if (survey['cheerful_spirits'] != null) data['QID6'] = survey['cheerful_spirits'].toString();
    if (survey['calm_relaxed'] != null) data['QID7'] = survey['calm_relaxed'].toString();
    if (survey['active_vigorous'] != null) data['QID8'] = survey['active_vigorous'].toString();
    if (survey['woke_up_fresh'] != null) data['QID9'] = survey['woke_up_fresh'].toString();
    if (survey['daily_life_interesting'] != null) data['QID10'] = survey['daily_life_interesting'].toString();
    
    // Personal characteristics (1-5 scale)
    if (survey['cooperate_with_people'] != null) data['QID11'] = survey['cooperate_with_people'].toString();
    if (survey['improving_skills'] != null) data['QID12'] = survey['improving_skills'].toString();
    if (survey['social_situations'] != null) data['QID13'] = survey['social_situations'].toString();
    if (survey['family_support'] != null) data['QID14'] = survey['family_support'].toString();
    if (survey['family_knows_me'] != null) data['QID15'] = survey['family_knows_me'].toString();
    if (survey['access_to_food'] != null) data['QID16'] = survey['access_to_food'].toString();
    if (survey['people_enjoy_time'] != null) data['QID17'] = survey['people_enjoy_time'].toString();
    if (survey['talk_to_family'] != null) data['QID18'] = survey['talk_to_family'].toString();
    if (survey['friends_support'] != null) data['QID19'] = survey['friends_support'].toString();
    if (survey['belong_in_community'] != null) data['QID20'] = survey['belong_in_community'].toString();
    if (survey['family_stands_by_me'] != null) data['QID21'] = survey['family_stands_by_me'].toString();
    if (survey['friends_stand_by_me'] != null) data['QID22'] = survey['friends_stand_by_me'].toString();
    if (survey['treated_fairly'] != null) data['QID23'] = survey['treated_fairly'].toString();
    if (survey['opportunities_responsibility'] != null) data['QID24'] = survey['opportunities_responsibility'].toString();
    if (survey['secure_with_family'] != null) data['QID25'] = survey['secure_with_family'].toString();
    if (survey['opportunities_abilities'] != null) data['QID26'] = survey['opportunities_abilities'].toString();
    if (survey['enjoy_cultural_traditions'] != null) data['QID27'] = survey['enjoy_cultural_traditions'].toString();
    
    // Digital diary
    if (survey['environmental_challenges'] != null) data['QID28'] = survey['environmental_challenges'];
    if (survey['challenges_stress_level'] != null) data['QID29'] = survey['challenges_stress_level'];
    if (survey['coping_help'] != null) data['QID30'] = survey['coping_help'];
    
    return data;
  }
}
