import 'package:flutter/material.dart';

class WellbeingSurveyResponse {
  final String id;
  final DateTime timestamp;
  final int? cheerfulSpirits; // null means user didn't answer this question
  final int? calmRelaxed; // null means user didn't answer this question
  final int? activeVigorous; // null means user didn't answer this question
  final int? wokeRested; // null means user didn't answer this question
  final int? interestingLife; // null means user didn't answer this question
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationTimestamp;
  final bool isSynced; // For research users - tracks if synced to server

  WellbeingSurveyResponse({
    required this.id,
    required this.timestamp,
    this.cheerfulSpirits, // Now optional - null means not answered
    this.calmRelaxed, // Now optional - null means not answered
    this.activeVigorous, // Now optional - null means not answered
    this.wokeRested, // Now optional - null means not answered
    this.interestingLife, // Now optional - null means not answered
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationTimestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'cheerful_spirits': cheerfulSpirits,
      'calm_relaxed': calmRelaxed,
      'active_vigorous': activeVigorous,
      'woke_rested': wokeRested,
      'interesting_life': interestingLife,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'location_timestamp': locationTimestamp,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory WellbeingSurveyResponse.fromJson(Map<String, dynamic> json) {
    return WellbeingSurveyResponse(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      cheerfulSpirits: json['cheerful_spirits'],
      calmRelaxed: json['calm_relaxed'],
      activeVigorous: json['active_vigorous'],
      wokeRested: json['woke_rested'],
      interestingLife: json['interesting_life'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      locationTimestamp: json['location_timestamp'],
      isSynced: (json['is_synced'] ?? 0) == 1,
    );
  }

  /// Calculate wellbeing score (0-5) based on answered survey responses
  /// Each "Yes" answer = 1 point, "No" answer = 0 points
  /// Null values (unanswered questions) are ignored in calculation
  int get wellbeingScore {
    final responses = [cheerfulSpirits, calmRelaxed, activeVigorous, wokeRested, interestingLife];
    final answeredResponses = responses.where((response) => response != null).cast<int>();
    return answeredResponses.isEmpty ? 0 : answeredResponses.reduce((a, b) => a + b);
  }

  /// Get number of questions answered (for calculating completion percentage)
  int get answeredQuestionCount {
    final responses = [cheerfulSpirits, calmRelaxed, activeVigorous, wokeRested, interestingLife];
    return responses.where((response) => response != null).length;
  }

  /// Get total number of questions
  int get totalQuestionCount => 5;

  /// Check if all questions were answered
  bool get isComplete => answeredQuestionCount == totalQuestionCount;

  /// Get wellbeing score as a normalized value (0.0 - 1.0) for color mapping
  /// Based on answered questions only
  double get normalizedWellbeingScore {
    if (answeredQuestionCount == 0) return 0.0;
    return wellbeingScore / answeredQuestionCount.toDouble();
  }

  /// Get wellbeing category based on score
  String get wellbeingCategory {
    switch (wellbeingScore) {
      case 0:
        return 'Very Low';
      case 1:
        return 'Low';
      case 2:
        return 'Below Average';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  /// Get color for wellbeing score (for map visualization)
  /// Red (low) to Green (high) gradient
  static Color getWellbeingColor(int score) {
    switch (score) {
      case 0:
        return const Color(0xFFD32F2F); // Dark Red
      case 1:
        return const Color(0xFFFF5722); // Red-Orange
      case 2:
        return const Color(0xFFFF9800); // Orange
      case 3:
        return const Color(0xFFFFC107); // Amber
      case 4:
        return const Color(0xFF8BC34A); // Light Green
      case 5:
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Creates a copy with updated sync status
  WellbeingSurveyResponse copyWithSyncStatus(bool synced) {
    return WellbeingSurveyResponse(
      id: id,
      timestamp: timestamp,
      cheerfulSpirits: cheerfulSpirits,
      calmRelaxed: calmRelaxed,
      activeVigorous: activeVigorous,
      wokeRested: wokeRested,
      interestingLife: interestingLife,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      locationTimestamp: locationTimestamp,
      isSynced: synced,
    );
  }

  /// For research data export - includes participant metadata
  Map<String, dynamic> toResearchJson(String participantCode) {
    return {
      'participant_code': participantCode,
      'survey_id': id,
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        'cheerful_spirits': cheerfulSpirits,
        'calm_relaxed': calmRelaxed,
        'active_vigorous': activeVigorous,
        'woke_rested': wokeRested,
        'interesting_life': interestingLife,
      },
      'location': latitude != null && longitude != null ? {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': locationTimestamp,
      } : null,
      'survey_type': 'wellbeing_action_button',
    };
  }
}

class WellbeingSurveyQuestion {
  final String id;
  final String text;
  final List<String> options;

  const WellbeingSurveyQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  static const List<String> yesNoOptions = [
    'Yes',
    'No',
  ];

  static const List<WellbeingSurveyQuestion> questions = [
    WellbeingSurveyQuestion(
      id: 'cheerful_spirits',
      text: 'Do you feel cheerful and in good spirits right now?',
      options: yesNoOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'calm_relaxed',
      text: 'Do you feel calm and relaxed right now?',
      options: yesNoOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'active_vigorous',
      text: 'Do you feel active and vigorous right now?',
      options: yesNoOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'woke_rested',
      text: 'Did you wake up today feeling fresh and rested?',
      options: yesNoOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'interesting_life',
      text: 'Has your life today been filled with things that interest you?',
      options: yesNoOptions,
    ),
  ];
}
