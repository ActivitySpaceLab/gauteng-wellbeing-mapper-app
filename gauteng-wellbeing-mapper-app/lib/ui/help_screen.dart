import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Guide'),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            SizedBox(height: 20),
            _buildMainScreenSection(),
            SizedBox(height: 20),
            _buildPermissionsSection(),
            SizedBox(height: 20),
            _buildMenuOptionsSection(),
            SizedBox(height: 20),
            _buildAppModesSection(),
            SizedBox(height: 20),
            _buildSurveySection(),
            SizedBox(height: 20),
            _buildPrivacySection(),
            SizedBox(height: 20),
            _buildTroubleshootingSection(),
            SizedBox(height: 20),
            _buildContactSection(),
          ],
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
            Row(
              children: [
                Icon(Icons.help_outline, color: SouthAfricanTheme.primaryBlue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Wellbeing Mapper helps people learn more about the ways in which mental wellbeing depends on environmental conditions. You can use it privately to study your own movements and wellbeing, experience research features safely with app testing mode, or participate in the Planet4Health study on mental wellbeing if you live in Gauteng, South Africa.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreenSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: SouthAfricanTheme.primaryGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  'Main Screen Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Location tracking switch
            _buildFeatureItem(
              Icons.toggle_on,
              'Location Tracking Switch',
              'The switch in the top-right corner controls location tracking:',
              [
                '• Yellow switch = Tracking ON (recording your movements)',
                '• Grey switch = Tracking OFF (not recording)',
                '• When ON, the app tracks your location in the background' 
              ],
            ),
            
            SizedBox(height: 16),
            
            // GPS button
            _buildFeatureItem(
              Icons.gps_fixed,
              'GPS Fix Button',
              'The GPS icon next to the switch:',
              [
                '• Tap to get your current precise location',
                '• Useful if the map seems outdated',
                '• Forces the app to check your exact position',
                '• The icon turns yellow when active'
              ],
            ),
            
            SizedBox(height: 16),
            
            // Survey button
            _buildFeatureItem(
              Icons.add_circle,
              'Survey Button (Blue Oval)',
              'The floating blue button in the bottom-right:',
              [
                '• Tap anytime to take a wellbeing survey',
                '• Available to all users (private and research mode)',
                '• Surveys help track how you feel in different places',
                '• Takes about 2-3 minutes to complete'
              ],
            ),
            
            SizedBox(height: 16),
            
            // Menu button
            _buildFeatureItem(
              Icons.menu,
              'Menu Button',
              'The hamburger menu (three lines) in the top-left:',
              [
                '• Opens the main navigation menu',
                '• Access all app features and settings',
                '• Different options based on your app mode',
                '• Tap anywhere outside menu to close'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: SouthAfricanTheme.accentYellow, size: 24),
                SizedBox(width: 8),
                Text(
                  'App Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            _buildFeatureItem(
              Icons.location_on,
              'Location Permission',
              'Required for the core functionality of tracking your movements:',
              [
                '• Allows the app to record where you spend time',
                '• Needed for wellbeing mapping and research features',
                '• You control whether location data is shared or kept private',
                '• The app will request this permission when you first choose your participation mode'
              ],
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureItem(
              Icons.notifications,
              'Notification Permission',
              'Optional but recommended for research participants:',
              [
                '• Sends bi-weekly survey reminders',
                '• Helps you stay engaged with the study',
                '• You can disable notifications anytime in phone settings',
                '• Private mode users won\'t receive research reminders'
              ],
            ),
            
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.softYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: SouthAfricanTheme.darkGrey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can manage all permissions in your phone\'s Settings app. The app will guide you through granting necessary permissions when you first set up your participation mode.',
                      style: TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildMenuOptionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: SouthAfricanTheme.accentYellow, size: 24),
                SizedBox(width: 8),
                Text(
                  'Menu Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Text(
              'Available to Everyone:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            
            _buildMenuOptionItem(
              Icons.list,
              'Locations History',
              'View a list of all recorded locations with timestamps and coordinates. You can delete individual entries by swiping left.',
            ),
            
            _buildMenuOptionItem(
              Icons.share,
              'Export Data',
              'Export all your location and survey data as a JSON file. This creates a backup you can save or share.',
            ),
            
            _buildMenuOptionItem(
              Icons.settings,
              'App Mode',
              'Switch between Private Mode (data stays on your phone), App Testing Mode (safely experience research features), and Research Mode (contribute to studies with encrypted data sharing).',
            ),
            
            _buildMenuOptionItem(
              Icons.help,
              'Help & Guide',
              'Opens this help screen with detailed instructions for using the app.',
            ),
            
            _buildMenuOptionItem(
              Icons.web,
              'Visit Project Website',
              'Opens the Planet4Health project website to learn more about the mental wellbeing research study.',
            ),
            
            _buildMenuOptionItem(
              Icons.report_problem_outlined,
              'Report an Issue',
              'Contact the research team if you experience technical problems or have questions.',
            ),
            
            SizedBox(height: 16),
            
            Text(
              'App Testing & Research Mode:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SouthAfricanTheme.researchMode),
            ),
            SizedBox(height: 8),
            
            _buildMenuOptionItem(
              Icons.assignment,
              'Initial Survey',
              'Complete a one-time survey when you first join the research study (available in app testing mode for practice).',
            ),
            
            _buildMenuOptionItem(
              Icons.assignment_turned_in,
              'Wellbeing Survey',
              'Take the bi-weekly wellbeing check-in survey. You\'ll also be reminded automatically in research mode.',
            ),
            
            _buildMenuOptionItem(
              Icons.history,
              'Survey History',
              'View all surveys you\'ve completed, including dates and your responses.',
            ),
            
            _buildMenuOptionItem(
              Icons.notifications_outlined,
              'Survey Notifications',
              'Manage when and how often you receive survey reminder notifications (research mode only).',
            ),
            
            _buildMenuOptionItem(
              Icons.cloud_upload,
              'Research Data Upload',
              'Manually upload your encrypted data to research servers (research mode only - app testing mode keeps data local).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppModesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_applications, color: SouthAfricanTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'App Modes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Private Mode
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.privateMode.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SouthAfricanTheme.privateMode.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: SouthAfricanTheme.privateMode),
                      SizedBox(width: 8),
                      Text(
                        'Private Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: SouthAfricanTheme.privateMode,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• All data stays on your phone only\n'
                    '• No automatic data sharing with researchers\n'
                    '• You control all data export and sharing\n'
                    '• Perfect for personal movement tracking\n'
                    '• Can still take wellbeing surveys for yourself',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // App Testing Mode
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'App Testing Mode 🧪',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Experience the full research consent process safely\n'
                    '• Practice taking surveys without submitting real data\n'
                    '• Test all app features in a safe environment\n'
                    '• Understand what research participation involves\n'
                    '• No data is sent to researchers (stays local only)',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Research Mode
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.researchMode.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SouthAfricanTheme.researchMode.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: SouthAfricanTheme.researchMode),
                      SizedBox(width: 8),
                      Text(
                        'Research Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: SouthAfricanTheme.researchMode,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Encrypted data shared with research team\n'
                    '• Contribute to important wellbeing studies\n'
                    '• Regular survey reminders every 2 weeks\n'
                    '• All participation is voluntary and anonymous\n'
                    '• Currently in development for future release',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.softYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: SouthAfricanTheme.darkGrey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can switch between Private and App Testing modes anytime. App Testing mode lets you safely experience research features without submitting real data.',
                      style: TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildSurveySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: SouthAfricanTheme.accentYellow, size: 24),
                SizedBox(width: 8),
                Text(
                  'About the Surveys',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Wellbeing surveys help researchers understand how your environment affects your mood, stress, and overall wellbeing.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 12),
            
            _buildFeatureItem(
              Icons.schedule,
              'When to Take Surveys',
              '',
              [
                '• Anytime using blue button on main screen',
                '• Research participants get reminders every 2 weeks',
                '• Best to take when you have 2-3 minutes',
                '• Try to answer honestly based on how you feel'
              ],
            ),
            
            SizedBox(height: 12),
            
            _buildFeatureItem(
              Icons.psychology,
              'What Surveys Ask',
              '',
              [
                '• How you\'re feeling emotionally',
                '• Your stress and anxiety levels',
                '• Safety and comfort in your current location',
                '• Social connections and community feeling',
                '• Physical health and energy levels'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: SouthAfricanTheme.primaryGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  'Privacy & Data Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            _buildFeatureItem(
              Icons.lock,
              'Data Protection',
              '',
              [
                '• All data is encrypted on your device',
                '• Location data never includes personal identifiers',
                '• You control what data to share and when',
                '• Research data is anonymous and aggregated'
              ],
            ),
            
            SizedBox(height: 12),
            
            _buildFeatureItem(
              Icons.visibility_off,
              'Your Privacy Rights',
              '',
              [
                '• You can stop participating anytime',
                '• Delete your data from the study',
                '• Export your data for personal use',
                '• Contact researchers with privacy concerns'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: SouthAfricanTheme.accentRed, size: 24),
                SizedBox(width: 8),
                Text(
                  'Troubleshooting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            _buildTroubleshootItem(
              'Location permission issues?',
              [
                '• Check that location permission is granted in phone settings',
                '• Some phones have "precise location" settings - enable this',
                '• Try restarting the app after granting permissions',
                '• On Android, ensure "Allow all the time" location access is enabled'
              ],
            ),
            
            _buildTroubleshootItem(
              'Location not updating?',
              [
                '• Check that location tracking switch is ON (yellow)',
                '• Tap the GPS button to force a location update',
                '• Ensure location permissions are enabled in phone settings',
                '• Try restarting the app if problems persist'
              ],
            ),
            
            _buildTroubleshootItem(
              'App running slowly?',
              [
                '• Close other apps running in the background',
                '• Restart your phone if needed',
                '• Clear some storage space on your device',
                '• Update to the latest version of the app'
              ],
            ),
            
            _buildTroubleshootItem(
              'Survey notifications not working?',
              [
                '• Check notification settings in your phone',
                '• Open "Survey Notifications" in the menu',
                '• Ensure the app has permission to send notifications',
                '• Try triggering a test notification'
              ],
            ),
            
            _buildTroubleshootItem(
              'App Testing Mode Questions?',
              [
                '• App Testing mode is completely safe - no real data is submitted',
                '• You can experience the full research workflow without commitment',
                '• All testing data stays on your phone only',
                '• Switch back to Private mode anytime through the menu'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_support, color: SouthAfricanTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'If you have questions or need assistance:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• Use "Report an Issue" in the menu\n'
              '• Visit the project website for more information\n'
              '• Contact the research team directly\n'
              '• Check for app updates in your app store',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Thank you for using Gauteng Wellbeing Mapper! Your participation helps researchers understand how communities and environments affect wellbeing in South Africa.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SouthAfricanTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 14)),
                  ],
                  SizedBox(height: 4),
                  ...points.map((point) => Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(point, style: TextStyle(fontSize: 14, height: 1.3)),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuOptionItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SouthAfricanTheme.mediumGrey, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: SouthAfricanTheme.darkGrey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, List<String> solutions) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            problem,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 6),
          ...solutions.map((solution) => Padding(
            padding: EdgeInsets.only(bottom: 2, left: 8),
            child: Text(solution, style: TextStyle(fontSize: 14, height: 1.3)),
          )).toList(),
        ],
      ),
    );
  }
}
