import 'dart:convert';
import 'dart:io';

/// Script to create a new Qualtrics consent survey based on the Planet4Health Consent Form 2025 PILOT blueprint
void main() async {
  print('🔧 Creating Qualtrics Consent Survey from Blueprint...\n');

  const String qualtricsToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const String qualtricsUrl = 'https://pretoria.eu.qualtrics.com';

  // Survey definition based on blueprint
  final surveyDefinition = {
    "SurveyName": "Gauteng Wellbeing Mapper - Consent Form (Blueprint)",
    "Language": "EN",
    "ProjectCategory": "CORE"
  };

  final client = HttpClient();
  
  try {
    // Step 1: Create the survey
    print('📝 Step 1: Creating survey...');
    final createRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions'));
    createRequest.headers.set('X-API-TOKEN', qualtricsToken);
    createRequest.headers.set('Content-Type', 'application/json');
    createRequest.write(jsonEncode(surveyDefinition));
    
    final createResponse = await createRequest.close();
    final createBody = await createResponse.transform(utf8.decoder).join();
    final createData = jsonDecode(createBody);
    
    if (createResponse.statusCode != 200) {
      print('❌ Failed to create survey: $createBody');
      return;
    }
    
    final surveyId = createData['result']['SurveyID'];
    print('✅ Survey created with ID: $surveyId');
    
    // Step 2: Add questions based on blueprint
    print('\\n📋 Step 2: Adding questions...');
    
    final questions = [
      {
        "QuestionText": "Participant Code",
        "DataExportTag": "QID1",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Participant code",
        "Validation": {
          "Settings": {
            "ForceResponse": "ON",
            "Type": "None"
          }
        }
      },
      {
        "QuestionText": "Participant UUID (Hidden)",
        "DataExportTag": "QID2", 
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Participant UUID (Hidden)",
        "DisplayLogic": {
          "0": {
            "0": {
              "LogicType": "Question",
              "QuestionID": "QID1",
              "QuestionIsInLoop": "no",
              "ChoiceLocator": "q://QID1/SelectedChoicesTextEntry",
              "Operator": "EqualTo",
              "RightOperand": "NEVER_SHOW_THIS",
              "Type": "Expression"
            },
            "Type": "BooleanExpression"
          },
          "Type": "BooleanExpression",
          "inPage": false
        }
      },
      {
        "QuestionText": "I give my consent to participate in this pilot study",
        "DataExportTag": "QID3",
        "QuestionType": "TE", 
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Informed consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent for my personal data to be processed by Qualtrics",
        "DataExportTag": "QID4",
        "QuestionType": "TE",
        "Selector": "SL", 
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Data processing consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to being asked about my race/ethnicity",
        "DataExportTag": "QID5",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Race/ethnicity consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to being asked about my health",
        "DataExportTag": "QID6",
        "QuestionType": "TE", 
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Health consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to being asked about my sexual orientation",
        "DataExportTag": "QID7",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Sexual orientation consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to being asked about my location and mobility",
        "DataExportTag": "QID8",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Location/mobility consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to transferring my personal data to countries outside South Africa",
        "DataExportTag": "QID9",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Data transfer consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to researchers reporting what I contribute publicly without my full name",
        "DataExportTag": "QID10",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Public reporting consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to what I contribute being shared with national and international researchers",
        "DataExportTag": "QID11",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Researcher sharing consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to what I contribute being used for further research or teaching purposes",
        "DataExportTag": "QID12",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Further research consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to what I contribute being placed in a public repository in deidentified form",
        "DataExportTag": "QID13",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Public repository consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "I give my consent to being contacted about participation in possible follow-up studies",
        "DataExportTag": "QID14",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Follow-up contact consent (1=yes, 0=no)"
      },
      {
        "QuestionText": "Participant signature/name",
        "DataExportTag": "QID15",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Participant signature"
      },
      {
        "QuestionText": "Consent timestamp (Hidden)",
        "DataExportTag": "QID16",
        "QuestionType": "TE",
        "Selector": "SL",
        "Configuration": {
          "QuestionDescriptionOption": "UseText"
        },
        "QuestionDescription": "Consent timestamp",
        "DisplayLogic": {
          "0": {
            "0": {
              "LogicType": "Question",
              "QuestionID": "QID1",
              "QuestionIsInLoop": "no",
              "ChoiceLocator": "q://QID1/SelectedChoicesTextEntry",
              "Operator": "EqualTo",
              "RightOperand": "NEVER_SHOW_THIS",
              "Type": "Expression"
            },
            "Type": "BooleanExpression"
          },
          "Type": "BooleanExpression",
          "inPage": false
        }
      }
    ];
    
    // Add each question
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      print('  Adding ${question['DataExportTag']}: ${question['QuestionDescription']}');
      
      final questionRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions/$surveyId/questions'));
      questionRequest.headers.set('X-API-TOKEN', qualtricsToken);
      questionRequest.headers.set('Content-Type', 'application/json');
      questionRequest.write(jsonEncode(question));
      
      final questionResponse = await questionRequest.close();
      final questionBody = await questionResponse.transform(utf8.decoder).join();
      
      if (questionResponse.statusCode != 200) {
        print('    ❌ Failed to add question: $questionBody');
      } else {
        print('    ✅ Added successfully');
      }
      
      // Small delay to avoid rate limits
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    // Step 3: Publish the survey
    print('\\n🚀 Step 3: Publishing survey...');
    final publishRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions/$surveyId/versions'));
    publishRequest.headers.set('X-API-TOKEN', qualtricsToken);
    publishRequest.headers.set('Content-Type', 'application/json');
    publishRequest.write(jsonEncode({
      "Published": true,
      "Description": "Blueprint version with all 16 consent questions"
    }));
    
    final publishResponse = await publishRequest.close();
    final publishBody = await publishResponse.transform(utf8.decoder).join();
    
    if (publishResponse.statusCode == 200) {
      print('✅ Survey published successfully!');
    } else {
      print('⚠️ Publication may have issues: $publishBody');
    }
    
    print('\\n🎉 SUCCESS! New consent survey created:');
    print('Survey ID: $surveyId');
    print('Survey Name: Gauteng Wellbeing Mapper - Consent Form (Blueprint)');
    print('Questions: 16 (QID1-QID16) according to blueprint specification');
    print('\\nNext steps:');
    print('1. Update _consentSurveyId in qualtrics_api_service.dart to: $surveyId');
    print('2. Test the consent form submission');
    print('3. Verify data appears correctly in Qualtrics');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}
