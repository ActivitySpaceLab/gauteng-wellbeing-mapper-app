import '../main.dart';
import '../services/location_encryption_service.dart';

class QualtricsSurveyService {
  // Qualtrics survey URLs
  static const String _initialSurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_byJSMxWDA88icbY';
  static const String _biweeklySurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_3aNJIQJXHPCyaOi';
  
  // Qualtrics field identifiers - these are the IDs set in the Qualtrics survey builder
  static const String _participantIdField = 'participant_id';
  static const String _locationJsonField = 'locations';

  /// Get the appropriate survey URL based on survey type
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
    final participantId = GlobalData.userUUID;
    
    String script = '''
      // Wait for Qualtrics to load
      setTimeout(function() {
        try {
          console.log('Starting Qualtrics field population...');
          
          // Method 1: Use Qualtrics Embedded Data API (preferred method)
          if (typeof Qualtrics !== 'undefined' && Qualtrics.SurveyEngine) {
            console.log('Using Qualtrics Embedded Data API');
            Qualtrics.SurveyEngine.setEmbeddedData('$_participantIdField', '$participantId');
            console.log('Set participant_id via embedded data: $participantId');
          }
          
          // Method 2: Try to find and set text input fields by various selectors
          var participantFields = [
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
            document.querySelector('.QuestionBody input[type="text"]'),
            // Try by Qualtrics-specific selectors
            document.querySelector('input[id*="QR~QID"][type="text"]')
          ].filter(field => field !== null);
          
          if (participantFields.length > 0) {
            participantFields.forEach(function(field, index) {
              field.value = '$participantId';
              field.dispatchEvent(new Event('input', {bubbles: true}));
              field.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set participant ID in field ' + index + ':', field);
            });
          } else {
            console.log('No participant ID fields found with direct selectors');
          }
          
          // Method 3: Search all text inputs for ones that might be the participant ID field
          var allTextInputs = document.querySelectorAll('input[type="text"]');
          allTextInputs.forEach(function(input) {
            var inputId = (input.id || '').toLowerCase();
            var inputName = (input.name || '').toLowerCase();
            var inputClass = (input.className || '').toLowerCase();
            
            if (inputId.includes('participant') || inputName.includes('participant') || 
                inputClass.includes('participant') || inputId.includes('$_participantIdField')) {
              input.value = '$participantId';
              input.dispatchEvent(new Event('input', {bubbles: true}));
              input.dispatchEvent(new Event('change', {bubbles: true}));
              console.log('Set participant ID in discovered field:', input);
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
            Qualtrics.SurveyEngine.setEmbeddedData('$_participantIdField', '$participantId');
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
