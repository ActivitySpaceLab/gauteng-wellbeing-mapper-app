import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/consent_models.dart';
import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../theme/south_african_theme.dart';

class ParticipationSelectionScreen extends StatefulWidget {
  @override
  _ParticipationSelectionScreenState createState() => _ParticipationSelectionScreenState();
}

class _ParticipationSelectionScreenState extends State<ParticipationSelectionScreen> {
  // Note: _participantCodeController kept for future research mode restoration
  final _participantCodeController = TextEditingController();
  String _selectedMode = 'private'; // 'private', 'appTesting'
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Welcome to Wellbeing Mapper',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeSection(),
            SizedBox(height: 32),
            _buildChoiceSection(),
            // Note: Participant code section removed for beta testing phase
            // Research participation will be re-enabled in future release
            SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.handshake, size: 64, color: Colors.blueGrey),
            SizedBox(height: 16),
            Text(
              'Wellbeing Mapper',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Reduced font size
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              'A privacy-focused app for mapping your mental wellbeing',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]), // Reduced font size
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            // Beta testing notice
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🧪 BETA VERSION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to use this app?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: RadioListTile<String>(
            value: 'private',
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            title: Text('Personal Use Only'),
            subtitle: Text('Use the app privately for your own wellbeing tracking. No data will be shared.'),
            secondary: Icon(Icons.lock, color: Colors.green),
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: RadioListTile<String>(
            value: 'appTesting',
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            title: Text('App Testing'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Test all app features safely. No real research data is collected or shared.'),
                SizedBox(height: 4),
                Text(
                  '• Experience all research features\n• Practice with surveys and mapping\n• All data stays local - nothing sent to servers',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            secondary: Icon(Icons.science, color: Colors.orange),
          ),
        ),
      ],
    );
  }

  // BETA TESTING: Research participation section disabled
  // This will be re-enabled in the full release for actual research participation
  /*
  Widget _buildParticipantCodeSection() {
    String studySite = 'Gauteng, South Africa';
    String exampleCode = 'GP2024-001';
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Research Participation - $studySite',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enter the participant code provided by the research team:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _participantCodeController,
              decoration: InputDecoration(
                labelText: 'Participant Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
                hintText: 'e.g., $exampleCode',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your participant code was provided when you were recruited for the study. If you don\'t have a code, please contact the research team.',
                      style: TextStyle(fontSize: 13, color: Colors.blue[800]),
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
  */

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMode == 'private' ? Colors.green : Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    _selectedMode == 'private' ? 'Start Using App' : 'Start App Testing',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        SizedBox(height: 12),
        TextButton(
          onPressed: _showContactInfo,
          child: Text('Contact Development Team'),
        ),
      ],
    );
  }

  void _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedMode == 'private') {
        // Private use flow
        await AppModeService.setCurrentMode(AppMode.private);
        await _savePrivateUserSettings();
      } else if (_selectedMode == 'appTesting') {
        // App testing flow
        await AppModeService.setCurrentMode(AppMode.appTesting);
        // No additional setup needed - app mode service handles test participant code generation
      }
      
      _navigateToMainApp();
    } catch (error) {
      _showErrorDialog('Error setting up app mode: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    
    // Note: Research participation flow disabled during beta testing
    // Future release will restore research mode with consent flow
  }

  Future<void> _savePrivateUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = ParticipationSettings.privateUser();
    await prefs.setString('participation_settings', jsonEncode(settings.toJson()));
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Development Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a beta testing version. For questions about the app:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Development Team:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• John Palmer: john.palmer@upf.edu'),
            SizedBox(height: 16),
            Text(
              'For future research participation information:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text('• Linda Theron: linda.theron@up.ac.za', style: TextStyle(fontSize: 12)),
            Text('• Caradee Wright: Caradee.Wright@mrc.ac.za', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _participantCodeController.dispose();
    super.dispose();
  }
}
