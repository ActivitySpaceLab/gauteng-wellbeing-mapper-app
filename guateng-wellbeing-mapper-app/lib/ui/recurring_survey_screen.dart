import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../models/app_mode.dart';
import '../db/survey_database.dart';
import '../services/consent_aware_upload_service.dart';
import '../services/app_mode_service.dart';

class RecurringSurveyScreen extends StatefulWidget {
  @override
  _RecurringSurveyScreenState createState() => _RecurringSurveyScreenState();
}

class _RecurringSurveyScreenState extends State<RecurringSurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  List<String> _voiceNoteUrls = [];
  List<File> _voiceNoteFiles = [];
  final ImagePicker _picker = ImagePicker();
  String _researchSite = 'barcelona'; // Default to Barcelona
  
  // Voice recording state
  bool _isRecording = false;
  bool _isPaused = false;
  
  // Audio playback state
  Map<String, bool> _playingStates = {};

  @override
  void initState() {
    super.initState();
    _loadResearchSite();
  }

  Future<void> _loadResearchSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final participationJson = prefs.getString('participation_settings');
      if (participationJson != null) {
        // Parse the JSON to get research site
        final Map<String, dynamic> participationData = Map<String, dynamic>.from(
          jsonDecode(participationJson)
        );
        
        final settings = ParticipationSettings.fromJson(participationData);
        setState(() {
          _researchSite = settings.researchSite ?? 'barcelona';
        });
      }
    } catch (e) {
      // Default to Barcelona if any error
      setState(() {
        _researchSite = 'barcelona';
      });
    }
  }

  // Gauteng-specific activity options based on survey_questions_gp.md
  final List<String> _gautengActivityOptions = [
    'Unemployed, looking for work',
    'Unemployed but NOT looking for work',
    'Temporary/seasonal labour',
    'Part-time employed',
    'Full-time employed',
    'Self employed',
    'Skills development course (e.g. learnership)',
    'Student',
    'Retired',
    'Homemaker',
    'Caring for children/ill relatives',
    'Volunteered',
    'Exercised',
    'Vacation',
    'Other'
  ];

  // Barcelona activity options (original)
  final List<String> _barcelonaActivityOptions = [
    'Employed',
    'Unemployed',
    'Student',
    'Homemaker',
    'Retired',
    'Unable to work',
    'Other'
  ];

  // Gauteng-specific living arrangement options
  final List<String> _gautengLivingArrangementOptions = [
    'alone',
    'others'
  ];

  // Barcelona living arrangement options (original)
  final List<String> _barcelonaLivingArrangementOptions = [
    'Living alone',
    'Living with family',
    'Living with friends/roommates',
    'Living with partner/spouse',
    'Other'
  ];

  // Gauteng-specific relationship options  
  final List<String> _gautengRelationshipOptions = [
    'Single',
    'In a committed relationship/married',
    'Separated',
    'Divorced',
    'Widowed'
  ];

  // Barcelona relationship options (original)
  final List<String> _barcelonaRelationshipOptions = [
    'Single',
    'In a relationship',
    'Married',
    'Divorced',
    'Widowed',
    'Prefer not to say'
  ];

  // Getters for site-specific options
  List<String> get _activityOptions => _researchSite == 'gauteng' 
      ? _gautengActivityOptions 
      : _barcelonaActivityOptions;
      
  List<String> get _livingArrangementOptions => _researchSite == 'gauteng' 
      ? _gautengLivingArrangementOptions 
      : _barcelonaLivingArrangementOptions;
      
  List<String> get _relationshipOptions => _researchSite == 'gauteng' 
      ? _gautengRelationshipOptions 
      : _barcelonaRelationshipOptions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Bi-weekly Wellbeing Survey',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              SizedBox(height: 24),
              _buildActivitiesSection(),
              SizedBox(height: 24),
              _buildLivingArrangementSection(),
              SizedBox(height: 24),
              _buildRelationshipSection(),
              SizedBox(height: 24),
              if (_researchSite == 'gauteng') ...[
                _buildHealthSection(),
                SizedBox(height: 24),
              ],
              _buildWellbeingSection(),
              SizedBox(height: 24),
              _buildPersonalCharacteristicsSection(),
              SizedBox(height: 24),
              _buildDigitalDiarySection(),
              SizedBox(height: 32),
              _buildSubmitButton(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bi-weekly Wellbeing Check-in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please take a few minutes to reflect on your wellbeing over the past two weeks.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return _buildSectionCard(
      title: _researchSite == 'gauteng' 
          ? 'What did you do with your time in the last two weeks?' 
          : 'Current Activities',
      subtitle: 'Mark ALL the choices that apply',
      child: FormBuilderCheckboxGroup<String>(
        name: 'activities',
        decoration: InputDecoration(border: InputBorder.none),
        options: _activityOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select at least one activity'), // Removed - now optional
      ),
    );
  }

  Widget _buildLivingArrangementSection() {
    return _buildSectionCard(
      title: _researchSite == 'gauteng'
          ? 'In the last two weeks, did you live alone or with others?'
          : 'Living Arrangement',
      child: FormBuilderRadioGroup<String>(
        name: 'livingArrangement',
        decoration: InputDecoration(border: InputBorder.none),
        options: _livingArrangementOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildRelationshipSection() {
    return _buildSectionCard(
      title: _researchSite == 'gauteng'
          ? 'What is your current relationship status? (Select the single best option)'
          : 'Relationship Status',
      child: FormBuilderRadioGroup<String>(
        name: 'relationshipStatus',
        decoration: InputDecoration(border: InputBorder.none),
        options: _relationshipOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildHealthSection() {
    return _buildSectionCard(
      title: 'General Health',
      child: FormBuilderRadioGroup<String>(
        name: 'generalHealth',
        decoration: InputDecoration(border: InputBorder.none),
        options: [
          FormBuilderFieldOption(value: 'Excellent', child: Text('Excellent')),
          FormBuilderFieldOption(value: 'Very good', child: Text('Very good')),
          FormBuilderFieldOption(value: 'Good', child: Text('Good')),
          FormBuilderFieldOption(value: 'Fair', child: Text('Fair')),
          FormBuilderFieldOption(value: 'Poor', child: Text('Poor')),
        ],
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildWellbeingSection() {
    return _buildSectionCard(
      title: 'Wellbeing Questions',
      subtitle: 'Over the past two weeks, how much of the time... (Scale: 0=Never, 5=All the time)',
      child: Column(
        children: [
          _buildRatingQuestion('cheerfulSpirits', 'Have you been in good spirits?', 0, 5),
          _buildRatingQuestion('calmRelaxed', 'Have you felt calm and relaxed?', 0, 5),
          _buildRatingQuestion('activeVigorous', 'Have you felt active and vigorous?', 0, 5),
          _buildRatingQuestion('wokeUpFresh', 'Did you wake up feeling fresh and rested?', 0, 5),
          _buildRatingQuestion('dailyLifeInteresting', 'Has your daily life been filled with things that interest you?', 0, 5),
        ],
      ),
    );
  }

  Widget _buildPersonalCharacteristicsSection() {
    return _buildSectionCard(
      title: 'Personal Characteristics',
      subtitle: 'Please rate how well each statement describes you (Scale: 1=Not at all, 5=Completely)',
      child: Column(
        children: [
          _buildRatingQuestion('cooperateWithPeople', 'I find it easy to cooperate with people', 1, 5),
          _buildRatingQuestion('improvingSkills', 'I am always improving my skills', 1, 5),
          _buildRatingQuestion('socialSituations', 'I feel comfortable in social situations', 1, 5),
          _buildRatingQuestion('familySupport', 'There is always someone in my family who can give me support', 1, 5),
          _buildRatingQuestion('familyKnowsMe', 'There is always someone in my family who really knows me', 1, 5),
          _buildRatingQuestion('accessToFood', 'I have access to the food I need', 1, 5),
          _buildRatingQuestion('peopleEnjoyTime', 'There are people with whom I enjoy spending time', 1, 5),
          _buildRatingQuestion('talkToFamily', 'I can talk about my problems with my family', 1, 5),
          _buildRatingQuestion('friendsSupport', 'My friends really try to help me', 1, 5),
          _buildRatingQuestion('belongInCommunity', 'I really feel like I belong in my community', 1, 5),
          _buildRatingQuestion('familyStandsByMe', 'My family really tries to stand by me', 1, 5),
          _buildRatingQuestion('friendsStandByMe', 'My friends really try to stand by me', 1, 5),
          _buildRatingQuestion('treatedFairly', 'I am treated fairly in my community', 1, 5),
          _buildRatingQuestion('opportunitiesResponsibility', 'I have opportunities to take responsibility', 1, 5),
          _buildRatingQuestion('secureWithFamily', 'I feel secure with my family', 1, 5),
          _buildRatingQuestion('opportunitiesAbilities', 'I have opportunities to show my abilities', 1, 5),
          _buildRatingQuestion('enjoyCulturalTraditions', 'I enjoy my community\'s cultural and traditional events', 1, 5),
        ],
      ),
    );
  }

  Widget _buildDigitalDiarySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Diary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // First prompt as a wrapped paragraph
            Text(
              _researchSite == 'gauteng'
                  ? 'What environmental challenges (e.g., poor air quality, heat, extreme weather) did you experience in the past 2 weeks?'
                  : 'What environmental challenges have you faced in the past two weeks? (e.g., extreme weather, air pollution, noise)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            FormBuilderTextField(
              name: 'environmentalChallenges',
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Please describe any environmental challenges...',
              ),
              maxLines: 3,
              minLines: 2,
            ),
            
            SizedBox(height: 20),
            
            // Second prompt as a wrapped paragraph
            Text(
              _researchSite == 'gauteng'
                  ? 'How stressful were these environmental challenges for you?'
                  : 'How would you rate the stress level of these challenges? Please explain.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            FormBuilderTextField(
              name: 'challengesStressLevel',
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Please describe the stress level...',
              ),
              maxLines: 3,
              minLines: 2,
            ),
            
            SizedBox(height: 20),
            
            // Third prompt as a wrapped paragraph
            Text(
              _researchSite == 'gauteng'
                  ? 'Who or what helped you to manage/cope with these environmental challenges?'
                  : 'What has helped you cope with these challenges?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            FormBuilderTextField(
              name: 'copingHelp',
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Please describe what helped you cope...',
              ),
              maxLines: 3,
              minLines: 2,
            ),
            
            SizedBox(height: 20),
            _buildVoiceNotesSection(),
            SizedBox(height: 16),
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingQuestion(String name, String question, int min, int max) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(question, style: TextStyle(fontSize: 16)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Current position is just a placeholder - move the slider if you want to provide a rating',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          FormBuilderSlider(
            name: name,
            min: min.toDouble(),
            max: max.toDouble(),
            initialValue: ((min + max) / 2).toDouble(), // Start at middle, but user knows it's just placeholder
            divisions: max - min,
            decoration: InputDecoration(
              border: InputBorder.none,
              helperText: '$min = ${min == 0 ? 'Never' : 'Not at all'}, $max = ${max == 5 ? 'All the time' : 'Completely'}',
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Notes (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Text(
          'Record voice notes to share additional thoughts or experiences about environmental challenges.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        
        // Display existing voice notes
        if (_voiceNoteFiles.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _voiceNoteFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                final fileName = file.path.split('/').last;
                final isPlaying = _playingStates[file.path] ?? false;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.mic, color: Colors.blue[700]),
                  ),
                  title: Text('Voice Note ${index + 1}'),
                  subtitle: Text(fileName, style: TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () => _togglePlayback(file.path),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeVoiceNote(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12),
        ],
        
        // Recording controls
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              if (_isRecording) ...[
                Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Recording...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text('Tap to stop', style: TextStyle(fontSize: 12)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pauseResumeRecording,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: Icon(Icons.stop),
                      label: Text('Stop & Save'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: _cancelRecording,
                      icon: Icon(Icons.cancel),
                      label: Text('Cancel'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: Icon(Icons.mic),
                  label: Text('Record Voice Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Text(
          'Add photos that relate to your environmental experiences (max 5 photos).',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${_selectedImages.length}/5 photos selected',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
        ],
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _selectedImages.length >= 5 ? null : _takePhoto,
              icon: Icon(Icons.camera_alt),
              label: Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _selectedImages.length >= 5 ? null : _selectFromGallery,
              icon: Icon(Icons.photo_library),
              label: Text('Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_selectedImages.length >= 5)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Maximum of 5 photos reached. Remove a photo to add more.',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, String? subtitle, required Widget child}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitSurvey,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Submit Survey',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  // Voice recording methods
  Future<void> _startRecording() async {
    try {
      // For now, show a placeholder dialog since we need to add the recording packages
      await _showRecordingDialog();
    } catch (e) {
      _showErrorDialog('Failed to start recording: $e');
    }
  }

  Future<void> _showRecordingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.red),
            SizedBox(width: 8),
            Text('Voice Recording'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voice recording functionality is being implemented.'),
            SizedBox(height: 16),
            Text('For now, you can use the text fields to describe your environmental experiences.'),
            SizedBox(height: 16),
            LinearProgressIndicator(),
            SizedBox(height: 8),
            Text('Recording simulation...', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateVoiceNote();
            },
            child: Text('Add Sample Voice Note'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _simulateVoiceNote() {
    // Add a simulated voice note for testing
    final now = DateTime.now();
    final fileName = 'voice_note_${now.millisecondsSinceEpoch}.m4a';
    
    setState(() {
      // Create a temporary file reference (in real implementation, this would be the actual recording)
      final tempFile = File('/tmp/$fileName'); // This won't actually exist, just for UI testing
      _voiceNoteFiles.add(tempFile);
      _voiceNoteUrls.add(tempFile.path);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample voice note added (actual recording will be implemented)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pauseResumeRecording() async {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
    
    // In real implementation, save the recording file here
    _simulateVoiceNote();
  }

  Future<void> _cancelRecording() async {
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }

  void _togglePlayback(String filePath) {
    setState(() {
      final isCurrentlyPlaying = _playingStates[filePath] ?? false;
      
      // Stop all other playbacks
      _playingStates.clear();
      
      // Toggle this one
      _playingStates[filePath] = !isCurrentlyPlaying;
    });

    // In real implementation, use audioplayers package to play/pause
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_playingStates[filePath]! ? 'Playing voice note...' : 'Stopped playback'),
        duration: Duration(seconds: 1),
      ),
    );

    // Simulate playback finishing after 3 seconds
    if (_playingStates[filePath]!) {
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _playingStates[filePath] = false;
          });
        }
      });
    }
  }

  void _removeVoiceNote(dynamic indexOrUrl) {
    if (indexOrUrl is int) {
      // Remove by index
      setState(() {
        if (indexOrUrl < _voiceNoteFiles.length) {
          final file = _voiceNoteFiles[indexOrUrl];
          _voiceNoteFiles.removeAt(indexOrUrl);
          _voiceNoteUrls.remove(file.path);
          _playingStates.remove(file.path);
        }
      });
    } else if (indexOrUrl is String) {
      // Remove by URL (legacy support)
      final index = _voiceNoteUrls.indexOf(indexOrUrl);
      if (index != -1) {
        _removeVoiceNote(index);
      }
    }
  }

  void _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: $e');
    }
  }

  void _selectFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to select images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitSurvey() async {
    // Always save and allow submission - no validation required
    _formKey.currentState?.save();
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = _formKey.currentState!.value;
      
      final surveyResponse = RecurringSurveyResponse(
        activities: List<String>.from(formData['activities'] ?? []),
        livingArrangement: formData['livingArrangement'],
        relationshipStatus: formData['relationshipStatus'],
        generalHealth: formData['generalHealth'],
        cheerfulSpirits: formData['cheerfulSpirits']?.round(),
        calmRelaxed: formData['calmRelaxed']?.round(),
        activeVigorous: formData['activeVigorous']?.round(),
        wokeUpFresh: formData['wokeUpFresh']?.round(),
        dailyLifeInteresting: formData['dailyLifeInteresting']?.round(),
        cooperateWithPeople: formData['cooperateWithPeople']?.round(),
        improvingSkills: formData['improvingSkills']?.round(),
        socialSituations: formData['socialSituations']?.round(),
        familySupport: formData['familySupport']?.round(),
        familyKnowsMe: formData['familyKnowsMe']?.round(),
        accessToFood: formData['accessToFood']?.round(),
        peopleEnjoyTime: formData['peopleEnjoyTime']?.round(),
        talkToFamily: formData['talkToFamily']?.round(),
        friendsSupport: formData['friendsSupport']?.round(),
        belongInCommunity: formData['belongInCommunity']?.round(),
        familyStandsByMe: formData['familyStandsByMe']?.round(),
        friendsStandByMe: formData['friendsStandByMe']?.round(),
        treatedFairly: formData['treatedFairly']?.round(),
        opportunitiesResponsibility: formData['opportunitiesResponsibility']?.round(),
        secureWithFamily: formData['secureWithFamily']?.round(),
        opportunitiesAbilities: formData['opportunitiesAbilities']?.round(),
        enjoyCulturalTraditions: formData['enjoyCulturalTraditions']?.round(),
        environmentalChallenges: formData['environmentalChallenges'],
        challengesStressLevel: formData['challengesStressLevel'],
        copingHelp: formData['copingHelp'],
        voiceNoteUrls: _voiceNoteFiles.isNotEmpty ? _voiceNoteFiles.map((f) => f.path).toList() : null,
        imageUrls: _selectedImages.isNotEmpty ? _selectedImages.map((f) => f.path).toList() : null,
        researchSite: _researchSite, // Use the loaded research site
        submittedAt: DateTime.now(),
      );

      // Save to local database
      await _saveSurveyResponse(surveyResponse);

      // Check if we're in app testing mode and show appropriate message
      final currentMode = await AppModeService.getCurrentMode();
      if (currentMode == AppMode.appTesting) {
        _showBetaTestingSuccessDialog();
      } else {
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveSurveyResponse(RecurringSurveyResponse response) async {
    try {
      final db = SurveyDatabase();
      await db.insertRecurringSurvey(response);
      print('Recurring survey saved to local database');
    } catch (e) {
      print('Error saving recurring survey: $e');
      rethrow;
    }
  }

  void _showSuccessDialog() async {
    // Check if user is a research participant
    bool isResearchParticipant = false;
    String? participantUuid;
    
    try {
      final db = SurveyDatabase();
      final consent = await db.getConsent();
      isResearchParticipant = consent != null;
      participantUuid = consent?.participantUuid;
    } catch (e) {
      print('Error checking research participation: $e');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Survey Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you for completing the wellbeing survey. Your responses have been saved.'),
            if (isResearchParticipant) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Research Participation',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'As a research participant, your data helps advance scientific understanding. Would you like to upload your survey responses and location data now?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isResearchParticipant) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('Skip Upload'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close success dialog
                
                if (participantUuid != null) {
                  // Trigger consent-aware upload
                  ConsentAwareDataUploadService.uploadWithConsent(
                    context: context,
                    participantUuid: participantUuid,
                    researchSite: _researchSite,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data uploaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Upload failed: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                  );
                } else {
                  Navigator.of(context).pop(); // Go back to previous screen
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Upload Data', style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('OK'),
            ),
          ],
        ],
      ),
    );
  }

  void _showBetaTestingSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('🧪 '),
            Text('Beta Testing Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your survey responses have been saved locally for testing purposes.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beta Testing Info',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'If this had been research mode, your data would have been submitted to researchers. Since this is beta testing, no data was transmitted.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '💙 Thank you for beta testing the Wellbeing Mapper!',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Got it!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to submit survey: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
