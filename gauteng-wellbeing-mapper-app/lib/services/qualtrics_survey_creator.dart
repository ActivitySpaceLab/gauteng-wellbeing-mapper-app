import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for creating Qualtrics surveys that match the Flutter app structure
class QualtricsSurveyCreator {
  // TODO: Replace with your actual Qualtrics API credentials
  static const String _baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  static const String _apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  
  /// Create all three surveys needed for the app
  static Future<Map<String, String>> createAllSurveys() async {
    try {
      final initialSurveyId = await createInitialSurvey();
      final biweeklySurveyId = await createBiweeklySurvey();
      final consentSurveyId = await createConsentSurvey();
      
      return {
        'initial': initialSurveyId,
        'biweekly': biweeklySurveyId,
        'consent': consentSurveyId,
      };
    } catch (e) {
      print('Error creating surveys: $e');
      rethrow;
    }
  }

  /// Create the Initial Survey in Qualtrics
  static Future<String> createInitialSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Initial Survey',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
      'Questions': _getInitialSurveyQuestions(),
    };

    return await _createSurvey(surveyDefinition);
  }

  /// Create the Biweekly Survey in Qualtrics
  static Future<String> createBiweeklySurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Biweekly Survey',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
      'Questions': _getBiweeklySurveyQuestions(),
    };

    return await _createSurvey(surveyDefinition);
  }

  /// Create the Consent Form Survey in Qualtrics
  static Future<String> createConsentSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Consent Form',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
      'Questions': _getConsentSurveyQuestions(),
    };

    return await _createSurvey(surveyDefinition);
  }

  /// Generic method to create a survey in Qualtrics
  static Future<String> _createSurvey(Map<String, dynamic> surveyDefinition) async {
    final url = Uri.parse('$_baseUrl/survey-definitions');
    
    print('🔄 Creating survey: ${surveyDefinition['SurveyName']}');
    print('📡 Sending request to: $url');
    
    final response = await http.post(
      url,
      headers: {
        'X-API-TOKEN': _apiToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(surveyDefinition),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('📊 Parsed response: $responseData');
      
      // Try different possible response structures
      String? surveyId;
      if (responseData['result'] != null && responseData['result']['id'] != null) {
        surveyId = responseData['result']['id'];
      } else if (responseData['result'] != null && responseData['result']['SurveyID'] != null) {
        surveyId = responseData['result']['SurveyID'];
      } else if (responseData['result'] != null) {
        // Sometimes the survey ID is directly in result
        surveyId = responseData['result'].toString();
      } else if (responseData['id'] != null) {
        surveyId = responseData['id'];
      }
      
      if (surveyId != null && surveyId.isNotEmpty) {
        print('✅ Created survey: ${surveyDefinition['SurveyName']} with ID: $surveyId');
        return surveyId;
      } else {
        throw Exception('Survey created but could not extract ID from response: $responseData');
      }
    } else {
      throw Exception('Failed to create survey: ${response.statusCode} - ${response.body}');
    }
  }

  /// Define Initial Survey questions - now includes all biweekly questions for baseline measurement
  static List<Map<String, dynamic>> _getInitialSurveyQuestions() {
    return [
      // Demographics section (original initial survey)
      {
        'QuestionID': 'QID_PARTICIPANT_UUID',
        'QuestionText': 'Participant UUID',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_AGE',
        'QuestionText': 'What is your age?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_ETHNICITY',
        'QuestionText': 'How do you describe your ethnicity? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Black African',
          '2': 'Coloured',
          '3': 'Indian/Asian',
          '4': 'White',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_GENDER',
        'QuestionText': 'How do you describe your gender?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Male',
          '2': 'Female',
          '3': 'Non-binary',
          '4': 'Prefer not to say',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_SEXUALITY',
        'QuestionText': 'How do you describe your sexuality?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Heterosexual',
          '2': 'Gay/Lesbian',
          '3': 'Bisexual',
          '4': 'Prefer not to say',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_BIRTH_PLACE',
        'QuestionText': 'Where were you born?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_SUBURB',
        'QuestionText': 'What suburb do you live in?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_BUILDING_TYPE',
        'QuestionText': 'What type of building do you live in?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'House',
          '2': 'Apartment/Flat',
          '3': 'Townhouse',
          '4': 'Informal settlement',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_HOUSEHOLD_ITEMS',
        'QuestionText': 'Which of the following items does your household have? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Electricity',
          '2': 'Running water',
          '3': 'Flush toilet',
          '4': 'Refrigerator',
          '5': 'Television',
          '6': 'Computer/Laptop',
          '7': 'Internet access',
          '8': 'Car',
        },
      },
      {
        'QuestionID': 'QID_EDUCATION',
        'QuestionText': 'What is your highest level of education?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'No formal education',
          '2': 'Primary school',
          '3': 'High school (incomplete)',
          '4': 'High school (complete)',
          '5': 'Technical/Vocational training',
          '6': 'University degree',
          '7': 'Postgraduate degree',
        },
      },
      {
        'QuestionID': 'QID_CLIMATE_ACTIVISM',
        'QuestionText': 'How involved are you in climate activism?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Not involved at all',
          '2': 'Slightly involved',
          '3': 'Moderately involved',
          '4': 'Very involved',
          '5': 'Extremely involved',
        },
      },
      {
        'QuestionID': 'QID_GENERAL_HEALTH',
        'QuestionText': 'How would you describe your general health?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Excellent',
          '2': 'Very good',
          '3': 'Good',
          '4': 'Fair',
          '5': 'Poor',
        },
      },
      
      // Baseline lifestyle questions (from biweekly survey)
      {
        'QuestionID': 'QID_ACTIVITIES_BASELINE',
        'QuestionText': 'What activities have you done recently? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Work',
          '2': 'Study',
          '3': 'Exercise',
          '4': 'Shopping',
          '5': 'Socializing',
          '6': 'Entertainment',
          '7': 'Travel',
          '8': 'Other',
        },
      },
      {
        'QuestionID': 'QID_LIVING_ARRANGEMENT',
        'QuestionText': 'Who do you currently live with?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Alone',
          '2': 'With family',
          '3': 'With friends/roommates',
          '4': 'With partner',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_RELATIONSHIP_STATUS',
        'QuestionText': 'What is your relationship status?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Single',
          '2': 'In a relationship',
          '3': 'Married',
          '4': 'Divorced',
          '5': 'Widowed',
        },
      },
      
      // Baseline wellbeing questions (0-5 scale)
      {
        'QuestionID': 'QID_CHEERFUL_SPIRITS_BASELINE',
        'QuestionText': 'Have you been in good spirits?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_CALM_RELAXED_BASELINE',
        'QuestionText': 'Have you felt calm and relaxed?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_ACTIVE_VIGOROUS_BASELINE',
        'QuestionText': 'Have you felt active and vigorous?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_WOKE_UP_FRESH_BASELINE',
        'QuestionText': 'Have you woken up feeling fresh and rested?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_DAILY_LIFE_INTERESTING_BASELINE',
        'QuestionText': 'Has your daily life been filled with things that interest you?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      
      // Baseline personal characteristics questions (1-5 scale)
      {
        'QuestionID': 'QID_COOPERATE_WITH_PEOPLE_BASELINE',
        'QuestionText': 'I am able to cooperate well with other people',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_IMPROVING_SKILLS_BASELINE',
        'QuestionText': 'I am always improving my skills',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SOCIAL_SITUATIONS_BASELINE',
        'QuestionText': 'I feel comfortable in social situations',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_SUPPORT_BASELINE',
        'QuestionText': 'My family really tries to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_KNOWS_ME_BASELINE',
        'QuestionText': 'My family knows me well',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ACCESS_TO_FOOD_BASELINE',
        'QuestionText': 'I have access to the food I need',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_PEOPLE_ENJOY_TIME_BASELINE',
        'QuestionText': 'People enjoy spending time with me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TALK_TO_FAMILY_BASELINE',
        'QuestionText': 'I can talk about my problems with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_SUPPORT_BASELINE',
        'QuestionText': 'My friends really try to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_BELONG_IN_COMMUNITY_BASELINE',
        'QuestionText': 'I feel like I belong in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_STANDS_BY_ME_BASELINE',
        'QuestionText': 'My family stands by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_STAND_BY_ME_BASELINE',
        'QuestionText': 'My friends stand by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TREATED_FAIRLY_BASELINE',
        'QuestionText': 'I am treated fairly in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_RESPONSIBILITY_BASELINE',
        'QuestionText': 'I have opportunities to take on responsibility',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SECURE_WITH_FAMILY_BASELINE',
        'QuestionText': 'I feel secure with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_ABILITIES_BASELINE',
        'QuestionText': 'I have opportunities to show my abilities',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ENJOY_CULTURAL_TRADITIONS_BASELINE',
        'QuestionText': 'I enjoy my cultural traditions',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      
      // Baseline digital diary questions (no location data for initial survey)
      {
        'QuestionID': 'QID_ENVIRONMENTAL_CHALLENGES_BASELINE',
        'QuestionText': 'What environmental challenges have you experienced recently?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_CHALLENGES_STRESS_LEVEL_BASELINE',
        'QuestionText': 'How stressful were these environmental challenges?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Not stressful at all',
          '2': 'Slightly stressful',
          '3': 'Moderately stressful',
          '4': 'Very stressful',
          '5': 'Extremely stressful',
        },
      },
      {
        'QuestionID': 'QID_COPING_HELP_BASELINE',
        'QuestionText': 'What has helped you cope with these challenges?',
        'QuestionType': 'TE',
      },
      
      // TODO: MULTIMEDIA DISABLED - Uncomment to re-enable multimedia support
      // {
      //   'QuestionID': 'QID_VOICE_NOTE_URLS_BASELINE',
      //   'QuestionText': 'Voice Note URLs (Internal - Baseline)',
      //   'QuestionType': 'TE',
      // },
      // {
      //   'QuestionID': 'QID_IMAGE_URLS_BASELINE',
      //   'QuestionText': 'Image URLs (Internal - Baseline)',
      //   'QuestionType': 'TE',
      // },
      
      // Metadata
      {
        'QuestionID': 'QID_RESEARCH_SITE',
        'QuestionText': 'Research Site',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_SUBMITTED_AT',
        'QuestionText': 'Submission Timestamp',
        'QuestionType': 'TE',
      },
    ];
  }

  /// Define Biweekly Survey questions based on Flutter RecurringSurveyResponse model
  static List<Map<String, dynamic>> _getBiweeklySurveyQuestions() {
    return [
      {
        'QuestionID': 'QID_PARTICIPANT_UUID',
        'QuestionText': 'Participant UUID',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_ACTIVITIES',
        'QuestionText': 'What activities have you done in the past two weeks? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Work',
          '2': 'Study',
          '3': 'Exercise',
          '4': 'Shopping',
          '5': 'Socializing',
          '6': 'Entertainment',
          '7': 'Travel',
          '8': 'Other',
        },
      },
      {
        'QuestionID': 'QID_LIVING_ARRANGEMENT',
        'QuestionText': 'Who do you currently live with?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Alone',
          '2': 'With family',
          '3': 'With friends/roommates',
          '4': 'With partner',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_RELATIONSHIP_STATUS',
        'QuestionText': 'What is your relationship status?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Single',
          '2': 'In a relationship',
          '3': 'Married',
          '4': 'Divorced',
          '5': 'Widowed',
        },
      },
      {
        'QuestionID': 'QID_GENERAL_HEALTH',
        'QuestionText': 'How would you describe your general health?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Excellent',
          '2': 'Very good',
          '3': 'Good',
          '4': 'Fair',
          '5': 'Poor',
        },
      },
      // Wellbeing questions (0-5 scale)
      {
        'QuestionID': 'QID_CHEERFUL_SPIRITS',
        'QuestionText': 'Have you been in good spirits?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_CALM_RELAXED',
        'QuestionText': 'Have you felt calm and relaxed?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_ACTIVE_VIGOROUS',
        'QuestionText': 'Have you felt active and vigorous?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_WOKE_UP_FRESH',
        'QuestionText': 'Have you woken up feeling fresh and rested?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_DAILY_LIFE_INTERESTING',
        'QuestionText': 'Has your daily life been filled with things that interest you?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      // Personal characteristics questions (1-5 scale)
      {
        'QuestionID': 'QID_COOPERATE_WITH_PEOPLE',
        'QuestionText': 'I am able to cooperate well with other people',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_IMPROVING_SKILLS',
        'QuestionText': 'I am always improving my skills',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SOCIAL_SITUATIONS',
        'QuestionText': 'I feel comfortable in social situations',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_SUPPORT',
        'QuestionText': 'My family really tries to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_KNOWS_ME',
        'QuestionText': 'My family knows me well',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ACCESS_TO_FOOD',
        'QuestionText': 'I have access to the food I need',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_PEOPLE_ENJOY_TIME',
        'QuestionText': 'People enjoy spending time with me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TALK_TO_FAMILY',
        'QuestionText': 'I can talk about my problems with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_SUPPORT',
        'QuestionText': 'My friends really try to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_BELONG_IN_COMMUNITY',
        'QuestionText': 'I feel like I belong in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_STANDS_BY_ME',
        'QuestionText': 'My family stands by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_STAND_BY_ME',
        'QuestionText': 'My friends stand by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TREATED_FAIRLY',
        'QuestionText': 'I am treated fairly in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_RESPONSIBILITY',
        'QuestionText': 'I have opportunities to take on responsibility',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SECURE_WITH_FAMILY',
        'QuestionText': 'I feel secure with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_ABILITIES',
        'QuestionText': 'I have opportunities to show my abilities',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ENJOY_CULTURAL_TRADITIONS',
        'QuestionText': 'I enjoy my cultural traditions',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      // Digital diary questions
      {
        'QuestionID': 'QID_ENVIRONMENTAL_CHALLENGES',
        'QuestionText': 'What environmental challenges have you experienced in the past two weeks?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_CHALLENGES_STRESS_LEVEL',
        'QuestionText': 'How stressful were these environmental challenges?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Not stressful at all',
          '2': 'Slightly stressful',
          '3': 'Moderately stressful',
          '4': 'Very stressful',
          '5': 'Extremely stressful',
        },
      },
      {
        'QuestionID': 'QID_COPING_HELP',
        'QuestionText': 'What has helped you cope with these challenges?',
        'QuestionType': 'TE',
      },
      
      // TODO: MULTIMEDIA DISABLED - Uncomment to re-enable multimedia support
      // {
      //   'QuestionID': 'QID_VOICE_NOTE_URLS',
      //   'QuestionText': 'Voice Note URLs (Internal)',
      //   'QuestionType': 'TE',
      // },
      // {
      //   'QuestionID': 'QID_IMAGE_URLS',
      //   'QuestionText': 'Image URLs (Internal)',
      //   'QuestionType': 'TE',
      // },
      {
        'QuestionID': 'QID_RESEARCH_SITE',
        'QuestionText': 'Research Site',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_SUBMITTED_AT',
        'QuestionText': 'Submission Timestamp',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_LOCATION_DATA',
        'QuestionText': 'Encrypted Location Data',
        'QuestionType': 'TE',
      },
    ];
  }

  /// Define Consent Form questions based on Flutter ConsentResponse model
  static List<Map<String, dynamic>> _getConsentSurveyQuestions() {
    return [
      {
        'QuestionID': 'QID_PARTICIPANT_CODE',
        'QuestionText': 'Participant Code',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_PARTICIPANT_UUID',
        'QuestionText': 'Participant UUID',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_INFORMED_CONSENT',
        'QuestionText': 'I understand the purpose and procedures of this research study',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_DATA_PROCESSING',
        'QuestionText': 'I consent to the processing of my personal data for research purposes',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_LOCATION_DATA',
        'QuestionText': 'I consent to the collection and use of my location data',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_SURVEY_DATA',
        'QuestionText': 'I consent to the collection and use of my survey responses',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_DATA_RETENTION',
        'QuestionText': 'I understand how my data will be stored and for how long',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_DATA_SHARING',
        'QuestionText': 'I consent to my anonymized data being shared for research purposes',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_VOLUNTARY_PARTICIPATION',
        'QuestionText': 'I understand that my participation is voluntary and I can withdraw at any time',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Agree',
          '0': 'Disagree',
        },
      },
      {
        'QuestionID': 'QID_PARTICIPANT_SIGNATURE',
        'QuestionText': 'Digital Signature (Name)',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_CONSENTED_AT',
        'QuestionText': 'Consent Timestamp',
        'QuestionType': 'TE',
      },
    ];
  }

  /// Method to print survey creation instructions
  static void printSetupInstructions() {
    print('''
=== QUALTRICS SURVEY SETUP INSTRUCTIONS ===

1. Replace 'YOUR_QUALTRICS_API_TOKEN_HERE' with your actual Qualtrics API token
2. Ensure your Qualtrics account has API access enabled
3. Run: QualtricsSurveyCreator.createAllSurveys()
4. Copy the returned survey IDs to your QualtricsApiService constants

Example usage:
```dart
final surveyIds = await QualtricsSurveyCreator.createAllSurveys();
print('Initial Survey ID: \${surveyIds['initial']}');
print('Biweekly Survey ID: \${surveyIds['biweekly']}');
print('Consent Survey ID: \${surveyIds['consent']}');
```

This will create three surveys in Qualtrics that exactly match your Flutter app structure:
- Initial Survey (demographics and baseline data)
- Biweekly Survey (wellbeing and location data)
- Consent Form (audit trail of consent decisions)
''');
  }
}
