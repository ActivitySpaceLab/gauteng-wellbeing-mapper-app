import 'location_encryption_service.dart';
import '../main.dart';
import 'participant_validation_service.dart';

class QualtricsSurveyService {
  // Field names in Qualtrics surveys
  static const String _participantIdField = 'participant_id';
  static const String _participantUuidField = 'participant_uuid'; // New field for UUID
  static const String _locationJsonField = 'locations';
  
  // Qualtrics survey URLs
  static const String _initialSurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_2bwK7iJ8xVFaEF0';
  static const String _biweeklySurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_cwZv97cK2DPlJ38';
  
  /// Get survey URL based on type
  static String getSurveyUrl(SurveyType surveyType) {
    switch (surveyType) {
      case SurveyType.initial:
        return _initialSurveyUrl;
      case SurveyType.biweekly:
        return _biweeklySurveyUrl;
    }
  }

  /// Generate JavaScript code to populate hidden fields in Qualtrics
  static Future<String> generateHiddenFieldScript(SurveyType surveyType, {String? locationJson}) async {
    // Get participant code (like "TESTER") instead of UUID
    final participantCode = await ParticipantValidationService.getValidatedParticipantCode() ?? 'UNKNOWN';
    final participantUuid = GlobalData.userUUID;
    
    String script = '''
      // Wait for Qualtrics to load
      setTimeout(function() {
        try {
          console.log('Starting Qualtrics field population...');
          console.log('Participant Code: $participantCode');
          console.log('Participant UUID: $participantUuid');
          
          // Method 1: Use Qualtrics Embedded Data API (preferred method)
          if (typeof Qualtrics !== 'undefined' && Qualtrics.SurveyEngine) {
            console.log('Using Qualtrics Embedded Data API');
            Qualtrics.SurveyEngine.setEmbeddedData('$_participantIdField', '$participantCode');
            Qualtrics.SurveyEngine.setEmbeddedData('$_participantUuidField', '$participantUuid');
            console.log('Set participant_id via embedded data: $participantCode');
            console.log('Set participant_uuid via embedded data: $participantUuid');
          }
          
          // Method 2: Try to find and set text input fields by various selectors
          
          // Handle participant_id field (should show participant code like "TESTER")
          var participantIdFields = [
            // Try by name attribute
            document.querySelector('input[name*="$_participantIdField"]'),
            // Try by id containing the field name
            document.querySelector('input[id*="$_participantIdField" i]'),
            // Try by class containing the field name
            document.querySelector('input[class*="$_participantIdField" i]'),
            // Try by data attributes
            document.querySelector('input[data-field="$_participantIdField"]'),
            document.querySelector('input[data-id="$_participantIdField"]'),
            // Try hidden inputs
            document.querySelector('input[type="hidden"][name*="$_participantIdField" i]'),
            // Try text inputs in Qualtrics question containers
            document.querySelector('.QuestionBody input[type="text"][id*="participant"]'),
            // Try by Qualtrics-specific selectors with participant in ID
            document.querySelector('input[id*="QR~QID"][type="text"][id*="participant" i]')
          ].filter(field => field !== null);
          
          if (participantIdFields.length > 0) {
            participantIdFields.forEach(function(field, index) {
              field.value = '$participantCode';
              field.dispatchEvent(new Event('input', {bubbles: true}));
              field.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set participant code in field ' + index + ':', field);
            });
          } else {
            console.log('No participant ID fields found with direct selectors');
          }
          
          // Handle participant_uuid field (separate field for UUID)
          var participantUuidFields = [
            document.querySelector('input[name*="$_participantUuidField"]'),
            document.querySelector('input[id*="$_participantUuidField" i]'),
            document.querySelector('input[class*="$_participantUuidField" i]'),
            document.querySelector('input[data-field="$_participantUuidField"]'),
            document.querySelector('input[data-id="$_participantUuidField"]'),
            document.querySelector('input[type="hidden"][name*="$_participantUuidField" i]'),
            document.querySelector('.QuestionBody input[type="text"][id*="uuid"]'),
            document.querySelector('input[id*="QR~QID"][type="text"][id*="uuid" i]')
          ].filter(field => field !== null);
          
          if (participantUuidFields.length > 0) {
            participantUuidFields.forEach(function(field, index) {
              field.value = '$participantUuid';
              field.dispatchEvent(new Event('input', {bubbles: true}));
              field.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set participant UUID in field ' + index + ':', field);
            });
          } else {
            console.log('No participant UUID fields found with direct selectors');
          }
          
          // Method 3: Search all text inputs for ones that might be participant fields
          var allTextInputs = document.querySelectorAll('input[type="text"]');
          allTextInputs.forEach(function(input) {
            var inputId = (input.id || '').toLowerCase();
            var inputName = (input.name || '').toLowerCase();
            var inputClass = (input.className || '').toLowerCase();
            
            // Check for participant_id pattern
            if (inputId.includes('participant') && !inputId.includes('uuid') || 
                inputName.includes('participant') && !inputName.includes('uuid') || 
                inputClass.includes('participant') && !inputClass.includes('uuid') || 
                inputId.includes('$_participantIdField')) {
              input.value = '$participantCode';
              input.dispatchEvent(new Event('input', {bubbles: true}));
              input.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set participant code in discovered field:', input);
            }
            
            // Check for participant_uuid pattern
            if (inputId.includes('uuid') || inputName.includes('uuid') || 
                inputClass.includes('uuid') || inputId.includes('$_participantUuidField')) {
              input.value = '$participantUuid';
              input.dispatchEvent(new Event('input', {bubbles: true}));
              input.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set participant UUID in discovered field:', input);
            }
          });
    ''';

    // Add encrypted location data for biweekly surveys
    if (surveyType == SurveyType.biweekly && locationJson != null && locationJson.isNotEmpty) {
      try {
        // Encrypt the location data before injecting
        final encryptedLocationData = await LocationEncryptionService.encryptLocationData(locationJson);
        
        // Escape the encrypted JSON string for JavaScript
        final escapedEncryptedData = encryptedLocationData
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r');
        
        script += '''
          
          // Set encrypted location data for biweekly survey
          console.log('Setting encrypted location data for biweekly survey...');
          
          // Method 1: Use Qualtrics Embedded Data API
          if (typeof Qualtrics !== 'undefined' && Qualtrics.SurveyEngine) {
            Qualtrics.SurveyEngine.setEmbeddedData('$_locationJsonField', '$escapedEncryptedData');
            console.log('Set encrypted locations via embedded data');
          }
          
          // Method 2: Try to find location fields by various selectors
          var locationFields = [
            document.querySelector('input[name*="$_locationJsonField"]'),
            document.querySelector('input[id*="$_locationJsonField" i]'),
            document.querySelector('input[class*="$_locationJsonField" i]'),
            document.querySelector('input[data-field="$_locationJsonField"]'),
            document.querySelector('input[data-id="$_locationJsonField"]'),
            document.querySelector('input[type="hidden"][name*="$_locationJsonField" i]'),
            document.querySelector('textarea[name*="$_locationJsonField" i]'),
            document.querySelector('textarea[id*="$_locationJsonField" i]')
          ].filter(field => field !== null);
          
          if (locationFields.length > 0) {
            locationFields.forEach(function(field, index) {
              field.value = '$escapedEncryptedData';
              field.dispatchEvent(new Event('input', {bubbles: true}));
              field.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set encrypted location data in field ' + index + ':', field);
            });
          } else {
            console.log('No location fields found with direct selectors');
          }
          
          // Method 3: Search all text inputs and textareas for location fields
          var allInputs = document.querySelectorAll('input[type="text"], textarea, input[type="hidden"]');
          allInputs.forEach(function(input) {
            var inputId = (input.id || '').toLowerCase();
            var inputName = (input.name || '').toLowerCase();
            var inputClass = (input.className || '').toLowerCase();
            
            if (inputId.includes('location') || inputName.includes('location') || 
                inputClass.includes('location') || inputId.includes('$_locationJsonField')) {
              input.value = '$escapedEncryptedData';
              input.dispatchEvent(new Event('input', {bubbles: true}));
              input.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set encrypted location data in discovered field:', input);
            }
          });
        ''';
      } catch (e) {
        // If encryption fails, log error but continue without location data
        script += '''
          
          console.error('Failed to encrypt location data: $e');
          console.log('Continuing without location data for privacy protection');
        ''';
      }
    }

    script += '''
          
          // Hide the populated fields from user view
          console.log('Hiding participant ID, UUID, and location fields...');
          
          // Hide participant ID fields
          var participantFieldsToHide = [
            document.querySelector('input[name*="$_participantIdField"]'),
            document.querySelector('input[id*="$_participantIdField" i]'),
            document.querySelector('input[class*="$_participantIdField" i]'),
            document.querySelector('input[data-field="$_participantIdField"]'),
            document.querySelector('input[data-id="$_participantIdField"]')
          ].filter(field => field !== null);
          
          // Hide participant UUID fields
          var participantUuidFieldsToHide = [
            document.querySelector('input[name*="$_participantUuidField"]'),
            document.querySelector('input[id*="$_participantUuidField" i]'),
            document.querySelector('input[class*="$_participantUuidField" i]'),
            document.querySelector('input[data-field="$_participantUuidField"]'),
            document.querySelector('input[data-id="$_participantUuidField"]')
          ].filter(field => field !== null);
          
          // Function to hide field and its containers
          function hideFieldAndContainers(field, fieldType) {
            // Hide the field itself
            field.style.display = 'none';
            field.style.visibility = 'hidden';
            
            // Try to hide the parent question container
            var questionContainer = field.closest('.QuestionOuter, .QuestionBody, .question, [class*="Question"]');
            if (questionContainer) {
              questionContainer.style.display = 'none';
              console.log('Hidden ' + fieldType + ' question container:', questionContainer);
            }
            
            // Try to hide parent div, tr, or other common containers
            var parentElement = field.parentElement;
            var attempts = 0;
            while (parentElement && parentElement !== document.body && attempts < 5) {
              if (parentElement.tagName === 'DIV' || parentElement.tagName === 'TR' || 
                  parentElement.className.includes('Question') || 
                  parentElement.className.includes('question')) {
                parentElement.style.display = 'none';
                console.log('Hidden ' + fieldType + ' parent container:', parentElement);
                break;
              }
              parentElement = parentElement.parentElement;
              attempts++;
            }
          }
          
          // Hide all participant ID fields
          participantFieldsToHide.forEach(function(field) {
            hideFieldAndContainers(field, 'participant ID');
          });
          
          // Hide all participant UUID fields
          participantUuidFieldsToHide.forEach(function(field) {
            hideFieldAndContainers(field, 'participant UUID');
          });
          
          // Hide location fields for biweekly surveys
          var locationFieldsToHide = [
            document.querySelector('input[name*="$_locationJsonField"]'),
            document.querySelector('input[id*="$_locationJsonField" i]'),
            document.querySelector('input[class*="$_locationJsonField" i]'),
            document.querySelector('input[data-field="$_locationJsonField"]'),
            document.querySelector('input[data-id="$_locationJsonField"]'),
            document.querySelector('textarea[name*="$_locationJsonField" i]'),
            document.querySelector('textarea[id*="$_locationJsonField" i]')
          ].filter(field => field !== null);
          
          locationFieldsToHide.forEach(function(field) {
            hideFieldAndContainers(field, 'location');
          });
          
          // Comprehensive search and hide - catch any fields that were missed
          var allInputsToCheck = document.querySelectorAll('input[type="text"], textarea, input[type="hidden"]');
          allInputsToCheck.forEach(function(input) {
            var inputId = (input.id || '').toLowerCase();
            var inputName = (input.name || '').toLowerCase();
            var inputClass = (input.className || '').toLowerCase();
            var inputValue = (input.value || '').toLowerCase();
            
            var isParticipantIdField = inputId.includes('participant') && !inputId.includes('uuid') || 
                                     inputName.includes('participant') && !inputName.includes('uuid') || 
                                     inputClass.includes('participant') && !inputClass.includes('uuid') || 
                                     inputId.includes('$_participantIdField');
            
            var isParticipantUuidField = inputId.includes('uuid') || inputName.includes('uuid') || 
                                       inputClass.includes('uuid') || inputId.includes('$_participantUuidField') ||
                                       inputValue.includes('$participantUuid');
            
            var isLocationField = inputId.includes('location') || inputName.includes('location') || 
                                inputClass.includes('location') || inputId.includes('$_locationJsonField');
            
            if (isParticipantIdField || isParticipantUuidField || isLocationField) {
              var fieldType = isParticipantIdField ? 'discovered participant ID' : 
                            isParticipantUuidField ? 'discovered participant UUID' : 'discovered location';
              hideFieldAndContainers(input, fieldType);
            }
          });
          
          console.log('Field hiding completed');
          
          // Mark hidden fields as answered to prevent validation errors
          console.log('Marking hidden fields as answered...');
          
          // Function to mark field as answered
          function markFieldAsAnswered(field, fieldType) {
            // Trigger validation events
            field.dispatchEvent(new Event('blur', {bubbles: true}));
            field.dispatchEvent(new Event('focusout', {bubbles: true}));
            field.dispatchEvent(new Event('change', {bubbles: true}));
            field.dispatchEvent(new Event('input', {bubbles: true}));
            
            // Mark field itself as valid
            field.classList.add('answered');
            field.classList.remove('error', 'validation-error');
            field.setAttribute('data-answered', 'true');
            
            // Mark question containers as answered/valid for Qualtrics validation
            var questionOuter = field.closest('.QuestionOuter');
            if (questionOuter) {
              questionOuter.classList.add('Answered');
              questionOuter.classList.remove('ValidationError', 'Error');
              questionOuter.setAttribute('data-answered', 'true');
            }
            
            var questionBody = field.closest('.QuestionBody');
            if (questionBody) {
              questionBody.classList.add('Answered');
              questionBody.classList.remove('ValidationError', 'Error');
              questionBody.setAttribute('data-answered', 'true');
            }
            
            // Also try other possible container classes
            var questionContainer = field.closest('.question, [class*="Question"]');
            if (questionContainer) {
              questionContainer.classList.add('Answered', 'answered');
              questionContainer.classList.remove('ValidationError', 'Error', 'error');
              questionContainer.setAttribute('data-answered', 'true');
            }
            
            console.log('Marked ' + fieldType + ' field as answered:', field);
          }
          
          // Mark participant ID fields as answered
          participantFieldsToHide.forEach(function(field) {
            markFieldAsAnswered(field, 'participant ID');
          });
          
          // Mark participant UUID fields as answered
          participantUuidFieldsToHide.forEach(function(field) {
            markFieldAsAnswered(field, 'participant UUID');
          });
          
          // Mark location fields as answered
          locationFieldsToHide.forEach(function(field) {
            markFieldAsAnswered(field, 'location');
          });
          
          // Additional comprehensive validation for any missed fields
          var allHiddenFields = document.querySelectorAll('input[style*="display: none"], input[style*="visibility: hidden"]');
          allHiddenFields.forEach(function(field) {
            if (field.value && field.value.trim() !== '') {
              markFieldAsAnswered(field, 'additional hidden');
            }
          });
          
          console.log('Hidden fields marked as answered');
          
          console.log('Qualtrics hidden fields population completed');
          
          // Send success feedback to mobile app
          if (typeof window.Print !== 'undefined') {
            window.Print.postMessage('FIELDS_POPULATED: Participant ID and encrypted location data injected');
          }
        } catch (error) {
          console.error('Error populating Qualtrics hidden fields:', error);
          
          // Send error feedback to mobile app
          if (typeof window.Print !== 'undefined') {
            window.Print.postMessage('FIELDS_ERROR: ' + error.message);
          }
        }
      }, 2000); // Wait 2 seconds for Qualtrics to fully initialize
      
      // Also try again after a longer delay in case Qualtrics takes time to render
      setTimeout(function() {
        try {
          if (typeof Qualtrics !== 'undefined' && Qualtrics.SurveyEngine) {
            Qualtrics.SurveyEngine.setEmbeddedData('$_participantIdField', '$participantCode');
            Qualtrics.SurveyEngine.setEmbeddedData('$_participantUuidField', '$participantUuid');
    ''';
    
    if (surveyType == SurveyType.biweekly && locationJson != null && locationJson.isNotEmpty) {
      try {
        final encryptedLocationData = await LocationEncryptionService.encryptLocationData(locationJson);
        final escapedEncryptedData = encryptedLocationData
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r');
        script += '''
            Qualtrics.SurveyEngine.setEmbeddedData('$_locationJsonField', '$escapedEncryptedData');
        ''';
      } catch (e) {
        script += '''
            console.error('Secondary encryption attempt failed: $e');
        ''';
      }
    }
    
    script += '''
            console.log('Secondary embedded data set completed');
            
            // Also hide any fields that might have loaded later
            console.log('Secondary field hiding attempt...');
            var delayedParticipantFields = document.querySelectorAll('input[name*="$_participantIdField"], input[id*="$_participantIdField" i]');
            var delayedParticipantUuidFields = document.querySelectorAll('input[name*="$_participantUuidField"], input[id*="$_participantUuidField" i]');
            var delayedLocationFields = document.querySelectorAll('input[name*="$_locationJsonField"], input[id*="$_locationJsonField" i], textarea[name*="$_locationJsonField" i]');
            
            // Hide delayed participant ID fields
            delayedParticipantFields.forEach(function(field) {
              field.style.display = 'none';
              field.style.visibility = 'hidden';
              var questionContainer = field.closest('.QuestionOuter, .QuestionBody, .question, [class*="Question"]');
              if (questionContainer) {
                questionContainer.style.display = 'none';
              }
            });
            
            // Hide delayed participant UUID fields
            delayedParticipantUuidFields.forEach(function(field) {
              field.style.display = 'none';
              field.style.visibility = 'hidden';
              var questionContainer = field.closest('.QuestionOuter, .QuestionBody, .question, [class*="Question"]');
              if (questionContainer) {
                questionContainer.style.display = 'none';
              }
            });
            
            // Hide delayed location fields
            delayedLocationFields.forEach(function(field) {
              field.style.display = 'none';
              field.style.visibility = 'hidden';
              var questionContainer = field.closest('.QuestionOuter, .QuestionBody, .question, [class*="Question"]');
              if (questionContainer) {
                questionContainer.style.display = 'none';
              }
            });
            
            // Look for any fields containing the UUID value and hide them
            var allInputsSecondCheck = document.querySelectorAll('input[type="text"], textarea');
            allInputsSecondCheck.forEach(function(input) {
              if (input.value && (input.value.includes('$participantUuid') || 
                                 input.value.includes('$participantCode'))) {
                input.style.display = 'none';
                input.style.visibility = 'hidden';
                var container = input.closest('.QuestionOuter, .QuestionBody, .question, [class*="Question"]');
                if (container) {
                  container.style.display = 'none';
                }
                console.log('Hidden field with detected participant data:', input);
              }
            });
            
            console.log('Secondary field hiding completed');
          }
        } catch (error) {
          console.error('Error in secondary embedded data setting:', error);
        }
      }, 5000); // Try again after 5 seconds
    ''';

    return script;
  }

  /// Get survey completion detection script for Qualtrics
  static String getSurveyCompletionScript() {
    return '''
      // Detect Qualtrics survey completion
      function checkForCompletion() {
        // Check for Qualtrics completion page indicators
        if (document.querySelector('.EndOfSurvey') || 
            document.querySelector('#EndOfSurvey') ||
            document.body.innerText.includes('Thank you') ||
            window.location.href.includes('complete') ||
            window.location.href.includes('thank')) {
          window.Print.postMessage('SURVEY_COMPLETED');
          return true;
        }
        return false;
      }
      
      // Check immediately and then periodically
      if (!checkForCompletion()) {
        var completionCheck = setInterval(function() {
          if (checkForCompletion()) {
            clearInterval(completionCheck);
          }
        }, 2000);
      }
    ''';
  }
}

enum SurveyType {
  initial,
  biweekly
}
