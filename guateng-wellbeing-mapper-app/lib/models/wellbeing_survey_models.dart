class WellbeingSurveyResponse {
  final String id;
  final DateTime timestamp;
  final int cheerfulSpirits;
  final int calmRelaxed;
  final int activeVigorous;
  final int wokeRested;
  final int interestingLife;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationTimestamp;
  final bool isSynced; // For research users - tracks if synced to server

  WellbeingSurveyResponse({
    required this.id,
    required this.timestamp,
    required this.cheerfulSpirits,
    required this.calmRelaxed,
    required this.activeVigorous,
    required this.wokeRested,
    required this.interestingLife,
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
