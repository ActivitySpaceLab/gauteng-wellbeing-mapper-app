import 'package:flutter/material.dart';
import '../services/consent_service.dart';
import '../theme/south_african_theme.dart';

class ChangeModeScreen extends StatefulWidget {
  @override
  _ChangeModeScreenState createState() => _ChangeModeScreenState();
}

class _ChangeModeScreenState extends State<ChangeModeScreen> {
  bool isPrivateUser = true;
  bool isLoading = true;
  String currentMode = 'Private';

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    try {
      final settings = await ConsentService.getParticipationSettings();
      setState(() {
        isPrivateUser = settings == null || !settings.isResearchParticipant;
        currentMode = isPrivateUser ? 'Private' : 'Research';
        isLoading = false;
      });
    } catch (e) {
      print('[ChangeModeScreen] Error loading participation settings: $e');
      setState(() {
        isPrivateUser = true;
        currentMode = 'Private';
        isLoading = false;
      });
    }
  }

  Future<void> _changeToPrivateMode() async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      'Switch to Private Mode',
      'Are you sure you want to switch to Private Mode?\n\n'
      '• Your data will no longer sync to research servers\n'
      '• You can still use all app features for personal tracking\n'
      '• You can export your data manually at any time\n'
      '• You can switch back to Research Mode later',
    );

    if (confirmed) {
      try {
        // Clear participation settings to switch to private mode
        await ConsentService.clearConsentData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully switched to Private Mode'),
            backgroundColor: SouthAfricanTheme.success,
          ),
        );
        
        // Return to previous screen with result
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching modes: $e'),
            backgroundColor: SouthAfricanTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _changeToResearchMode() async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      'Switch to Research Mode',
      'To switch to Research Mode, you will need to:\n\n'
      '• Enter a research participant code\n'
      '• Review and agree to the research consent form\n'
      '• Complete initial setup surveys\n\n'
      'Would you like to continue?',
    );

    if (confirmed) {
      // Navigate to participation selection screen for research setup
      final result = await Navigator.of(context).pushNamed('/participation_selection');
      if (result == true) {
        // Refresh the current mode after successful setup
        await _loadCurrentMode();
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SouthAfricanTheme.primaryBlue,
              foregroundColor: SouthAfricanTheme.pureWhite,
            ),
            child: Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildCurrentModeCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPrivateUser ? Icons.lock : Icons.science,
                  color: isPrivateUser ? SouthAfricanTheme.privateMode : SouthAfricanTheme.researchMode,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Mode: $currentMode',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPrivateUser ? SouthAfricanTheme.privateModeDark : SouthAfricanTheme.researchModeDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (isPrivateUser) ...[
              Text(
                'You are currently using the app in Private Mode.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                '• All your data stays on your device\n'
                '• No automatic syncing to research servers\n'
                '• You can export your data manually anytime\n'
                '• Perfect for personal wellbeing tracking',
                style: TextStyle(fontSize: 14, color: SouthAfricanTheme.darkGrey),
              ),
            ] else ...[
              Text(
                'You are currently participating in research.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                '• Your data is encrypted and synced to research servers\n'
                '• You contribute to important wellbeing research\n'
                '• All participation is voluntary and anonymous\n'
                '• You can stop participating at any time',
                style: TextStyle(fontSize: 14, color: SouthAfricanTheme.darkGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangeModeCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Want to change modes?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            if (isPrivateUser) ...[
              Text(
                'Switch to Research Mode to contribute to mental wellbeing research in Gauteng.',
                style: TextStyle(fontSize: 14, color: SouthAfricanTheme.darkGrey),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _changeToResearchMode,
                  icon: Icon(Icons.science),
                  label: Text('Switch to Research Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SouthAfricanTheme.researchMode,
                    foregroundColor: SouthAfricanTheme.pureWhite,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Switch to Private Mode to keep all your data on your device only.',
                style: TextStyle(fontSize: 14, color: SouthAfricanTheme.darkGrey),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _changeToPrivateMode,
                  icon: Icon(Icons.lock),
                  label: Text('Switch to Private Mode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SouthAfricanTheme.privateMode,
                    foregroundColor: SouthAfricanTheme.pureWhite,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Mode'),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          'App Mode Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: SouthAfricanTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choose how you want to use the Gauteng Wellbeing Mapper app.',
                          style: TextStyle(
                            fontSize: 16,
                            color: SouthAfricanTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Current mode card
                  _buildCurrentModeCard(),

                  // Change mode card
                  _buildChangeModeCard(),

                  // Info section
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SouthAfricanTheme.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SouthAfricanTheme.mediumGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: SouthAfricanTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              'Important Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• You can switch between modes at any time\n'
                          '• Your existing data will be preserved when switching modes\n'
                          '• In Private Mode, data is never sent to servers automatically\n'
                          '• In Research Mode, data is encrypted before transmission\n'
                          '• All research participation is voluntary and anonymous',
                          style: TextStyle(fontSize: 14, color: SouthAfricanTheme.darkGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
