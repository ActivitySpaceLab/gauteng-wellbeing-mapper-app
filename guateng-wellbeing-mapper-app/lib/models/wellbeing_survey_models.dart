class WellbeingSurveyResponse {
  final String id;
  final DateTime timestamp;
  final int cheerfulSpirits;
  final int calmRelaxed;
  final int activeVigorous;
  final int wokeRested;
  final int interestingLife;
  final bool isSynced; // For research users - tracks if synced to server

  WellbeingSurveyResponse({
    required this.id,
    required this.timestamp,
    required this.cheerfulSpirits,
    required this.calmRelaxed,
    required this.activeVigorous,
    required this.wokeRested,
    required this.interestingLife,
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

  static const List<String> likertOptions = [
    'At no time',
    'Some of the time',
    'Less than half of the time',
    'More than half of the time',
    'Most of the time',
    'All of the time',
  ];

  static const List<WellbeingSurveyQuestion> questions = [
    WellbeingSurveyQuestion(
      id: 'cheerful_spirits',
      text: 'I have felt cheerful in good spirits',
      options: likertOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'calm_relaxed',
      text: 'I have felt calm and relaxed',
      options: likertOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'active_vigorous',
      text: 'I have felt active and vigorous',
      options: likertOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'woke_rested',
      text: 'I woke up feeling fresh and rested',
      options: likertOptions,
    ),
    WellbeingSurveyQuestion(
      id: 'interesting_life',
      text: 'My daily life has been filled with things that interest me',
      options: likertOptions,
    ),
  ];
}
