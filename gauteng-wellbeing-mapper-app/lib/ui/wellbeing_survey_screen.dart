import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../models/wellbeing_survey_models.dart';
import '../services/wellbeing_survey_service.dart';
import '../services/app_mode_service.dart';
import '../models/app_mode.dart';
import '../theme/south_african_theme.dart';

class WellbeingSurveyScreen extends StatefulWidget {
  @override
  _WellbeingSurveyScreenState createState() => _WellbeingSurveyScreenState();
}

class _WellbeingSurveyScreenState extends State<WellbeingSurveyScreen> {
  double? _happinessScore; // 0.0 to 10.0, null means not answered
  bool _isSubmitting = false;
  bool _isCaptingLocation = false;
  bg.Location? _currentLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCaptingLocation = true;
      _locationError = null;
    });

    try {
      // Skip background geolocation on web platform
      if (kIsWeb) {
        print('[WellbeingSurveyScreen] Web platform detected - skipping location capture');
        setState(() {
          _locationError = 'Location capture not available on web platform';
          _isCaptingLocation = false;
        });
        return;
      }
      
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
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = WellbeingSurveyService.createResponse(
        happinessScore: _happinessScore,
        latitude: _currentLocation?.coords.latitude,
        longitude: _currentLocation?.coords.longitude,
        accuracy: _currentLocation?.coords.accuracy,
        locationTimestamp: _currentLocation?.timestamp,
      );

      await WellbeingSurveyService().insertWellbeingSurvey(response);

      // Check if we're in app testing mode
      final currentMode = await AppModeService.getCurrentMode();
      final hasAnswer = _happinessScore != null;
      
      if (currentMode == AppMode.appTesting) {
        // Show beta testing message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧪 Beta Testing Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  hasAnswer 
                    ? 'Your happiness rating of ${_happinessScore!.toStringAsFixed(1)} would have been submitted if this was research mode, but no data was transmitted since this is beta testing.'
                    : 'Your survey would have been submitted if this was research mode, but no data was transmitted since this is beta testing.',
                ),
                SizedBox(height: 8),
                Text(
                  '💙 Thank you for beta testing the Wellbeing Mapper!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: SouthAfricanTheme.primaryBlue,
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        // Show regular success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasAnswer 
                ? 'Wellbeing survey submitted successfully! Happiness rating: ${_happinessScore!.toStringAsFixed(1)}/10'
                : 'Wellbeing survey submitted successfully!',
            ),
            backgroundColor: SouthAfricanTheme.success,
          ),
        );
      }

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

  Widget _buildHappinessSlider() {
    final question = WellbeingSurveyQuestion.question;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Happiness Survey (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              question.text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            
            // Slider
            Column(
              children: [
                Slider(
                  value: _happinessScore ?? 5.0,
                  min: question.minValue,
                  max: question.maxValue,
                  divisions: 10, // 0, 1, 2, ..., 10
                  label: _happinessScore?.toStringAsFixed(1) ?? '5.0',
                  onChanged: (value) {
                    setState(() {
                      _happinessScore = value;
                    });
                  },
                  activeColor: SouthAfricanTheme.primaryBlue,
                  inactiveColor: Colors.grey[300],
                ),
                
                // Labels below slider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          question.minLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          question.maxLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Current value display
            if (_happinessScore != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SouthAfricanTheme.softYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mood,
                      color: SouthAfricanTheme.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Your happiness: ${_happinessScore!.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: SouthAfricanTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happiness Survey'),
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
                  'Happiness Survey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rate how happy you are feeling right now using the slider below.',
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
            child: SingleChildScrollView(
              child: _buildHappinessSlider(),
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
                  backgroundColor: Colors.blue,
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
