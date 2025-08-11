import 'location_encryption_service.dart';
import '../main.dart';

class QualtricsSurveyService {
  // Field names in Qualtrics surveys
  static const String _participantIdField = 'participant_id';
  static const String _participantUuidField = 'participant_uuid'; // New field for UUID
  static const String _locationJsonField = 'locations';
  
  // Survey URLs - these are the correct production survey URLs
  static const String _initialSurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_bsb8iq0UiATXRJQ';
  static const String _biweeklySurveyUrl = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_eUJstaSWQeKykBM';

  /// Generate JavaScript to populate hidden fields in Qualtrics survey
  static Future<String> populateHiddenFields(String participantCode, SurveyType surveyType, {String? locationJson}) async {
    final participantUuid = GlobalData.userUUID;
    
    String script = '''
      setTimeout(function() {
        try {
          console.log('=== QUALTRICS FIELD POPULATION START ===');
          console.log('Participant Code: $participantCode');
          console.log('Participant UUID: $participantUuid');
          
          // Debug: List all form fields
          var allFields = document.querySelectorAll('input, textarea');
          console.log('Total form fields found: ' + allFields.length);
          
          allFields.forEach(function(field, index) {
            console.log('Field ' + index + ': ' + field.tagName + 
                       ' name=' + (field.name || 'none') + 
                       ' id=' + (field.id || 'none') + 
                       ' type=' + (field.type || 'none'));
          });
          
          // Function to find and populate fields
          function populateFieldsByTerms(searchTerms, value, description) {
            var foundFields = [];
            
            // Search all input and textarea elements
            allFields.forEach(function(field) {
              var name = (field.name || '').toLowerCase();
              var id = (field.id || '').toLowerCase();
              var className = (field.className || '').toLowerCase();
              var placeholder = (field.placeholder || '').toLowerCase();
              
              // Check if any search term matches
              var matches = searchTerms.some(function(term) {
                return name.includes(term) || id.includes(term) || 
                       className.includes(term) || placeholder.includes(term);
              });
              
              if (matches) {
                foundFields.push(field);
              }
            });
            
            console.log('Found ' + foundFields.length + ' fields for ' + description);
            
            // Populate and hide each field
            var successCount = 0;
            foundFields.forEach(function(field, index) {
              try {
                // Set value
                field.value = value;
                field.setAttribute('value', value);
                
                // Trigger events for Qualtrics
                field.dispatchEvent(new Event('input', {bubbles: true}));
                field.dispatchEvent(new Event('change', {bubbles: true}));
                field.dispatchEvent(new Event('blur', {bubbles: true}));
                
                // Hide field completely
                field.style.display = 'none !important';
                field.style.visibility = 'hidden !important';
                field.style.opacity = '0';
                field.style.position = 'absolute';
                field.style.left = '-9999px';
                field.readOnly = true;
                field.setAttribute('tabindex', '-1');
                
                // Hide parent containers
                var parent = field.parentElement;
                var attempts = 0;
                while (parent && parent !== document.body && attempts < 5) {
                  var parentClass = (parent.className || '').toLowerCase();
                  if (parentClass.includes('question') || parentClass.includes('inner') || 
                      parentClass.includes('outer') || parentClass.includes('body')) {
                    parent.style.display = 'none !important';
                    parent.style.height = '0px !important';
                    parent.style.overflow = 'hidden !important';
                    console.log('Hidden container: ' + parent.className);
                    break;
                  }
                  parent = parent.parentElement;
                  attempts++;
                }
                
                successCount++;
                console.log('Successfully populated ' + description + ' field ' + index + ': ' + (field.name || field.id));
                
              } catch (error) {
                console.error('Error populating field: ' + error.message);
              }
            });
            
            return successCount > 0;
          }
          
          // Populate participant ID fields
          var participantIdTerms = ['participant_id', 'participant-id', 'participantid', 'participant', 'code'];
          var participantIdSuccess = populateFieldsByTerms(participantIdTerms, '$participantCode', 'participant ID');
          
          // Populate participant UUID fields
          var participantUuidTerms = ['participant_uuid', 'participant-uuid', 'uuid'];
          var participantUuidSuccess = populateFieldsByTerms(participantUuidTerms, '$participantUuid', 'participant UUID');
          
          console.log('Participant ID populated: ' + participantIdSuccess);
          console.log('Participant UUID populated: ' + participantUuidSuccess);''';

    // Add location data for biweekly surveys
    if (surveyType == SurveyType.biweekly && locationJson != null && locationJson.isNotEmpty) {
      try {
        final encryptedLocationData = await LocationEncryptionService.encryptLocationData(locationJson);
        final escapedData = encryptedLocationData
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r');
        
        script += '''
          
          // Populate location fields with encrypted data
          var locationTerms = ['locations', 'location', 'coords', 'gps'];
          var locationSuccess = populateFieldsByTerms(locationTerms, '$escapedData', 'location data');
          console.log('Location data populated: ' + locationSuccess);''';
      } catch (e) {
        script += '''
          
          console.error('Location encryption failed: $e');''';
      }
    }

    script += '''
          
          // Try Qualtrics API if available
          if (typeof Qualtrics !== 'undefined' && Qualtrics.SurveyEngine) {
            try {
              Qualtrics.SurveyEngine.setEmbeddedData('$_participantIdField', '$participantCode');
              Qualtrics.SurveyEngine.setEmbeddedData('$_participantUuidField', '$participantUuid');''';
              
    if (surveyType == SurveyType.biweekly) {
      script += '''
              Qualtrics.SurveyEngine.setEmbeddedData('$_locationJsonField', 'ENCRYPTED_DATA');''';
    }
    
    script += '''
              console.log('Qualtrics API embedded data set successfully');
            } catch (apiError) {
              console.error('Qualtrics API error: ' + apiError.message);
            }
          } else {
            console.log('Qualtrics API not available, using direct field population only');
          }
          
          console.log('=== FIELD POPULATION COMPLETED ===');
          
          // Send success notification to app
          if (typeof window.Print !== 'undefined') {
            window.Print.postMessage('FIELDS_POPULATED: Data processed and hidden successfully');
          }
          
        } catch (error) {
          console.error('=== FIELD POPULATION ERROR ===');
          console.error('Error details: ' + error.message);
          console.error('Stack trace: ' + error.stack);
          
          if (typeof window.Print !== 'undefined') {
            window.Print.postMessage('FIELDS_ERROR: ' + error.message);
          }
        }
      }, 3000); // Wait 3 seconds for full page load''';

    return script;
  }

  /// Get survey completion detection script
  static String _getSurveyCompletionScript() {
    return '''
      // Survey completion detection
      function checkForCompletion() {
        if (document.querySelector('#EndOfSurvey') ||
            document.querySelector('.EndOfSurvey') ||
            document.querySelector('#EndOfMessage') ||
            document.body.innerText.includes('Thank you') ||
            document.body.innerText.includes('completed') ||
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

  /// Get the survey URL based on type
  static String getSurveyUrl(SurveyType surveyType) {
    switch (surveyType) {
      case SurveyType.initial:
        return _initialSurveyUrl;
      case SurveyType.biweekly:
        return _biweeklySurveyUrl;
    }
  }

  /// Get the complete JavaScript for a survey
  static Future<String> getSurveyJavaScript(String participantCode, SurveyType surveyType, {String? locationJson}) async {
    final fieldScript = await populateHiddenFields(participantCode, surveyType, locationJson: locationJson);
    final completionScript = _getSurveyCompletionScript();
    
    return fieldScript + '\n\n' + completionScript;
  }
}

enum SurveyType {
  initial,
  biweekly
}
