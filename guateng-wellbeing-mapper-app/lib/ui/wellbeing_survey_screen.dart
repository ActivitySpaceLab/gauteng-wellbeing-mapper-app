import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../models/wellbeing_survey_models.dart';
import '../services/wellbeing_survey_service.dart';
import '../theme/south_african_theme.dart';

class WellbeingSurveyScreen extends StatefulWidget {
  @override
  _WellbeingSurveyScreenState createState() => _WellbeingSurveyScreenState();
}

class _WellbeingSurveyScreenState extends State<WellbeingSurveyScreen> {
  final Map<String, int?> _responses = {};
  bool _isSubmitting = false;
  bool _isCaptingLocation = false;
  bg.Location? _currentLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Initialize responses map
    for (final question in WellbeingSurveyQuestion.questions) {
      _responses[question.id] = null;
    }
    _captureLocation();
  }

  bool get _allQuestionsAnswered {
    return _responses.values.every((response) => response != null);
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCaptingLocation = true;
      _locationError = null;
    });

    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        persist: false,
        desiredAccuracy: 40,
        maximumAge: 10000,
        timeout: 30,
        samples: 3,
        extras: {"wellbeing_survey": true}
      );
      
      setState(() {
        _currentLocation = location;
        _isCaptingLocation = false;
      });
      
      print('[WellbeingSurveyScreen] Location captured: ${location.coords.latitude}, ${location.coords.longitude}');
    } catch (error) {
      setState(() {
        _locationError = error.toString();
        _isCaptingLocation = false;
      });
      
      print('[WellbeingSurveyScreen] Location capture error: $error');
    }
  }

  Future<void> _submitSurvey() async {
    if (!_allQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please answer all questions before submitting.'),
        backgroundColor: SouthAfricanTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = WellbeingSurveyService.createResponse(
        cheerfulSpirits: _responses['cheerful_spirits']!,
        calmRelaxed: _responses['calm_relaxed']!,
        activeVigorous: _responses['active_vigorous']!,
        wokeRested: _responses['woke_rested']!,
        interestingLife: _responses['interesting_life']!,
        latitude: _currentLocation?.coords.latitude,
        longitude: _currentLocation?.coords.longitude,
        accuracy: _currentLocation?.coords.accuracy,
        locationTimestamp: _currentLocation?.timestamp,
      );

      await WellbeingSurveyService().insertWellbeingSurvey(response);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wellbeing survey submitted successfully!'),
          backgroundColor: SouthAfricanTheme.success,
        ),
      );

      // Close the screen
      Navigator.of(context).pop();
    } catch (e) {
      print('[WellbeingSurveyScreen] Error submitting survey: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting survey. Please try again.'),
          backgroundColor: SouthAfricanTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildLocationStatus() {
    if (_isCaptingLocation) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(SouthAfricanTheme.primaryBlue),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Capturing location...',
            style: TextStyle(
              fontSize: 12,
              color: SouthAfricanTheme.primaryBlue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (_currentLocation != null) {
      return Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Colors.green,
          ),
          SizedBox(width: 4),
          Text(
            'Location captured (±${_currentLocation!.coords.accuracy.round()}m)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
            ),
          ),
        ],
      );
    } else if (_locationError != null) {
      return Row(
        children: [
          Icon(
            Icons.location_off,
            size: 16,
            color: Colors.orange,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Location unavailable - survey will be saved without location',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildQuestionCard(WellbeingSurveyQuestion question, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              question.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'How have you felt in the past 2 weeks:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              
              return RadioListTile<int>(
                title: Text(
                  optionText,
                  style: TextStyle(fontSize: 16),
                ),
                value: optionIndex,
                groupValue: _responses[question.id],
                onChanged: (value) {
                  setState(() {
                    _responses[question.id] = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Wellbeing Survey'),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: SouthAfricanTheme.softYellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mental Wellbeing Survey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please answer all questions about how you feel right now.',
                  style: TextStyle(
                    fontSize: 14,
                    color: SouthAfricanTheme.darkGrey,
                  ),
                ),
                SizedBox(height: 8),
                _buildLocationStatus(),
              ],
            ),
          ),
          
          // Questions
          Expanded(
            child: ListView.builder(
              itemCount: WellbeingSurveyQuestion.questions.length,
              itemBuilder: (context, index) {
                final question = WellbeingSurveyQuestion.questions[index];
                return _buildQuestionCard(question, index);
              },
            ),
          ),
          
          // Submit button
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allQuestionsAnswered ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(
                        'Submit Survey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
