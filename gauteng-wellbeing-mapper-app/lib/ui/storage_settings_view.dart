import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_settings_service.dart';

class StorageSettingsView extends StatefulWidget {
  @override
  _StorageSettingsViewState createState() => _StorageSettingsViewState();
}

class _StorageSettingsViewState extends State<StorageSettingsView> {
  int _locationRetentionDays = StorageSettingsService.DEFAULT_LOCATION_RETENTION_DAYS;
  int _mapDisplayDays = StorageSettingsService.DEFAULT_MAP_DISPLAY_DAYS;
  int _maxMapMarkers = StorageSettingsService.DEFAULT_MAX_MAP_MARKERS;
  bool _autoCleanupEnabled = StorageSettingsService.DEFAULT_AUTO_CLEANUP_ENABLED;
  
  Map<String, dynamic> _storageStats = {};
  bool _isLoading = true;
  bool _isPerformingCleanup = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStorageStats();
  }

  Future<void> _loadSettings() async {
    try {
      final retentionDays = await StorageSettingsService.getLocationRetentionDays();
      final displayDays = await StorageSettingsService.getMapDisplayDays();
      final maxMarkers = await StorageSettingsService.getMaxMapMarkers();
      final autoCleanup = await StorageSettingsService.getAutoCleanupEnabled();
      
      if (mounted) {
        setState(() {
          _locationRetentionDays = retentionDays;
          _mapDisplayDays = displayDays;
          _maxMapMarkers = maxMarkers;
          _autoCleanupEnabled = autoCleanup;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[StorageSettingsView] Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStorageStats() async {
    try {
      final stats = await StorageSettingsService.getStorageStats();
      if (mounted) {
        setState(() {
          _storageStats = stats;
        });
      }
    } catch (e) {
      print('[StorageSettingsView] Error loading storage stats: $e');
    }
  }

  Future<void> _updateLocationRetentionDays(int days) async {
    await StorageSettingsService.setLocationRetentionDays(days);
    setState(() {
      _locationRetentionDays = days;
    });
    _showSettingUpdatedSnackBar('Location data retention updated to $days days');
  }

  Future<void> _updateMapDisplayDays(int days) async {
    await StorageSettingsService.setMapDisplayDays(days);
    setState(() {
      _mapDisplayDays = days;
    });
    _showSettingUpdatedSnackBar('Map display period updated to $days days');
  }

  Future<void> _updateMaxMapMarkers(int markers) async {
    await StorageSettingsService.setMaxMapMarkers(markers);
    setState(() {
      _maxMapMarkers = markers;
    });
    _showSettingUpdatedSnackBar('Maximum map markers updated to $markers');
  }

  Future<void> _updateAutoCleanup(bool enabled) async {
    await StorageSettingsService.setAutoCleanupEnabled(enabled);
    setState(() {
      _autoCleanupEnabled = enabled;
    });
    _showSettingUpdatedSnackBar('Auto cleanup ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> _performManualCleanup() async {
    setState(() {
      _isPerformingCleanup = true;
    });

    try {
      await StorageSettingsService.performCleanup();
      await _loadStorageStats(); // Refresh stats
      _showSettingUpdatedSnackBar('Manual cleanup completed successfully');
    } catch (e) {
      _showErrorSnackBar('Cleanup failed: $e');
    }

    setState(() {
      _isPerformingCleanup = false;
    });
  }

  void _showSettingUpdatedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStorageStatsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (_storageStats.isEmpty)
              Text('Loading statistics...')
            else ...[
              _buildStatRow('Total Locations', '${_storageStats['totalLocations'] ?? 0}'),
              if (_storageStats['oldestDate'] != null)
                _buildStatRow('Oldest Data', _formatDate(_storageStats['oldestDate'])),
              if (_storageStats['newestDate'] != null)
                _buildStatRow('Newest Data', _formatDate(_storageStats['newestDate'])),
              if (_storageStats['dataSpanDays'] != null)
                _buildStatRow('Data Span', '${_storageStats['dataSpanDays']} days'),
              if (_storageStats['totalLocationTracks'] != null)
                _buildStatRow('Database Records', '${_storageStats['totalLocationTracks']}'),
            ],
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPerformingCleanup ? null : _performManualCleanup,
                child: _isPerformingCleanup
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Cleaning up...'),
                        ],
                      )
                    : Text('Clean Up Old Data Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 8),
            Row(
              children: [
                Text('$min'),
                Expanded(
                  child: Slider(
                    value: value.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    label: value.toString(),
                    onChanged: (double newValue) {
                      onChanged(newValue.round());
                    },
                  ),
                ),
                Text('$max'),
              ],
            ),
            Text(
              'Current: $value ${title.toLowerCase().contains('days') ? 'days' : 'markers'}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
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
        title: Text('Storage Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Location Data Storage',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Configure how long location data is stored on your device and how much is displayed on the map.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  
                  _buildStorageStatsCard(),
                  SizedBox(height: 16),
                  
                  _buildSliderSetting(
                    'Location Data Retention',
                    'How many days to keep location data on device',
                    _locationRetentionDays,
                    7,
                    90,
                    _updateLocationRetentionDays,
                  ),
                  SizedBox(height: 8),
                  
                  _buildSliderSetting(
                    'Map Display Period',
                    'How many recent days to show on map',
                    _mapDisplayDays,
                    1,
                    30,
                    _updateMapDisplayDays,
                  ),
                  SizedBox(height: 8),
                  
                  _buildSliderSetting(
                    'Maximum Map Markers',
                    'Maximum number of location points to display',
                    _maxMapMarkers,
                    100,
                    2000,
                    _updateMaxMapMarkers,
                  ),
                  SizedBox(height: 8),
                  
                  _buildSwitchSetting(
                    'Automatic Cleanup',
                    'Automatically remove old data daily',
                    _autoCleanupEnabled,
                    _updateAutoCleanup,
                  ),
                  
                  SizedBox(height: 20),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Storage Tips',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('• Shorter retention periods save device storage'),
                          Text('• Fewer map markers improve performance'),
                          Text('• Auto cleanup runs once daily'),
                          Text('• Survey data always includes 14 days of location history'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
