import 'package:flutter/material.dart';
import '../models/data_sharing_consent.dart';
import '../services/data_upload_service.dart';
import '../db/survey_database.dart';
import '../theme/south_african_theme.dart';

/// Dialog that prompts research participants for their consent before uploading data
class DataSharingConsentDialog extends StatefulWidget {
  final String participantUuid;
  final String researchSite;
  final VoidCallback onUploadProceed;
  final VoidCallback onUploadCancelled;

  const DataSharingConsentDialog({
    Key? key,
    required this.participantUuid,
    required this.researchSite,
    required this.onUploadProceed,
    required this.onUploadCancelled,
  }) : super(key: key);

  @override
  _DataSharingConsentDialogState createState() => _DataSharingConsentDialogState();
}

class _DataSharingConsentDialogState extends State<DataSharingConsentDialog> {
  LocationSharingOption _selectedOption = LocationSharingOption.fullData;
  bool _isLoading = true;
  DataUploadSummary? _dataSummary;
  Set<String> _selectedClusterIds = Set<String>(); // Track selected location clusters

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
  }

  Future<void> _loadDataSummary() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get recent location tracks
      final locationTracks = await DataUploadService.getRecentLocationTracks();

      // Get survey count
      final db = SurveyDatabase();
      final initialSurveys = await db.getInitialSurveys();
      final recurringSurveys = await db.getRecurringSurveys();
      final totalSurveys = initialSurveys.length + recurringSurveys.length;

      // Create clusters for location preview
      final clusters = _createLocationClusters(locationTracks);

      if (locationTracks.isNotEmpty) {
        final dates = locationTracks.map((track) => track.timestamp).toList()..sort();
        final accuracies = locationTracks.map((track) => track.accuracy ?? 0.0).where((acc) => acc > 0);
        final avgAccuracy = accuracies.isNotEmpty 
            ? accuracies.reduce((a, b) => a + b) / accuracies.length 
            : 0.0;

        setState(() {
          _dataSummary = DataUploadSummary(
            surveyResponseCount: totalSurveys,
            locationTrackCount: locationTracks.length,
            oldestLocationDate: dates.first,
            newestLocationDate: dates.last,
            locationAccuracyStats: avgAccuracy,
            locationClusters: clusters,
          );
          
          // Initialize all clusters as selected for partial sharing
          _selectedClusterIds.clear();
          for (int i = 0; i < clusters.length; i++) {
            _selectedClusterIds.add('cluster_$i');
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _dataSummary = DataUploadSummary(
            surveyResponseCount: totalSurveys,
            locationTrackCount: 0,
            oldestLocationDate: DateTime.now().subtract(Duration(days: 14)),
            newestLocationDate: DateTime.now(),
            locationAccuracyStats: 0.0,
            locationClusters: [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data summary: $e');
    }
  }

  List<LocationCluster> _createLocationClusters(List<LocationTrack> tracks) {
    if (tracks.isEmpty) return [];
    
    // Simple clustering by proximity (this could be enhanced with proper clustering algorithms)
    final clusters = <LocationCluster>[];
    const double clusterRadius = 0.01; // Roughly 1km
    
    for (final track in tracks) {
      bool addedToCluster = false;
      
      for (int i = 0; i < clusters.length; i++) {
        final cluster = clusters[i];
        final distance = _calculateDistance(
          track.latitude, track.longitude,
          cluster.centerLatitude, cluster.centerLongitude,
        );
        
        if (distance <= clusterRadius) {
          // Add to existing cluster (simplified - would need proper centroid calculation)
          clusters[i] = LocationCluster(
            areaName: cluster.areaName,
            trackCount: cluster.trackCount + 1,
            centerLatitude: cluster.centerLatitude,
            centerLongitude: cluster.centerLongitude,
            firstVisit: track.timestamp.isBefore(cluster.firstVisit) ? track.timestamp : cluster.firstVisit,
            lastVisit: track.timestamp.isAfter(cluster.lastVisit) ? track.timestamp : cluster.lastVisit,
          );
          addedToCluster = true;
          break;
        }
      }
      
      if (!addedToCluster) {
        clusters.add(LocationCluster(
          areaName: _getAreaName(track.latitude, track.longitude),
          trackCount: 1,
          centerLatitude: track.latitude,
          centerLongitude: track.longitude,
          firstVisit: track.timestamp,
          lastVisit: track.timestamp,
        ));
      }
    }
    
    return clusters;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple Euclidean distance approximation for clustering
    return ((lat1 - lat2).abs() + (lon1 - lon2).abs());
  }

  String _getAreaName(double latitude, double longitude) {
    // Simple area naming based on coordinates (could be enhanced with reverse geocoding)
    return "Area ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}";
  }

  void _handleOptionChanged(LocationSharingOption? option) {
    if (option != null) {
      setState(() {
        _selectedOption = option;
        // Clear any previous selections when switching options
        if (option != LocationSharingOption.partialData) {
          _selectedClusterIds.clear();
        }
      });
    }
  }

  void _proceedWithUpload() async {
    try {
      // Prepare custom location IDs for partial sharing
      List<String>? customLocationIds;
      if (_selectedOption == LocationSharingOption.partialData) {
        customLocationIds = _selectedClusterIds.toList();
      }

      // Save user's consent decision
      final consent = DataSharingConsent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationSharingOption: _selectedOption,
        decisionTimestamp: DateTime.now(),
        participantUuid: widget.participantUuid,
        customLocationIds: customLocationIds,
      );

      // Store consent in database
      final db = SurveyDatabase();
      await db.insertDataSharingConsent(consent);

      Navigator.of(context).pop();
      widget.onUploadProceed();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving consent: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Data Sharing Consent',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: _isLoading ? _buildLoadingContent() : _buildConsentContent(),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onUploadCancelled();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_canProceedWithUpload() ? null : _proceedWithUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: SouthAfricanTheme.primaryBlue,
          ),
          child: Text(
            'Continue Upload',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      width: double.maxFinite,
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: SouthAfricanTheme.primaryBlue,
            ),
            SizedBox(height: 16),
            Text('Analyzing your data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentContent() {
    return Container(
      width: double.maxFinite,
      constraints: BoxConstraints(maxHeight: 500),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You are about to upload your research data. Please choose how much location data you\'d like to share:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            _buildDataSummary(),
            SizedBox(height: 20),
            _buildSharingOptions(),
            SizedBox(height: 16),
            _buildPrivacyNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    if (_dataSummary == null) return SizedBox.shrink();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Survey Responses: ${_dataSummary!.surveyResponseCount}'),
            Text('Location Records: ${_dataSummary!.locationTrackCount}'),
            if (_dataSummary!.locationTrackCount > 0) ...[
              Text('Date Range: ${_formatDate(_dataSummary!.oldestLocationDate)} - ${_formatDate(_dataSummary!.newestLocationDate)}'),
              Text('Location Areas: ${_dataSummary!.locationClusters.length} different areas'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSharingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Data Sharing Options:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        
        RadioListTile<LocationSharingOption>(
          title: Text('Share Full Location Data'),
          subtitle: Text('Upload complete 2-week location history (${_dataSummary?.locationTrackCount ?? 0} records)'),
          value: LocationSharingOption.fullData,
          groupValue: _selectedOption,
          onChanged: _handleOptionChanged,
          activeColor: SouthAfricanTheme.primaryBlue,
        ),
        
        RadioListTile<LocationSharingOption>(
          title: Text('Share Partial Location Data'),
          subtitle: Text('Choose which location areas to share (all selected by default)'),
          value: LocationSharingOption.partialData,
          groupValue: _selectedOption,
          onChanged: _handleOptionChanged,
          activeColor: SouthAfricanTheme.primaryBlue,
        ),
        
        // Show location cluster selection when partial data is selected
        if (_selectedOption == LocationSharingOption.partialData)
          _buildLocationClusterSelection(),
        
        RadioListTile<LocationSharingOption>(
          title: Text('Survey Responses Only'),
          subtitle: Text('Upload only survey answers, no location data'),
          value: LocationSharingOption.surveyOnly,
          groupValue: _selectedOption,
          onChanged: _handleOptionChanged,
          activeColor: SouthAfricanTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Privacy Protection',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• All data is encrypted before upload\n'
            '• No personal identifiers are included\n'
            '• You can change this preference anytime\n'
            '• You can withdraw from the study at any point',
            style: TextStyle(fontSize: 13, color: Colors.green[800]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _canProceedWithUpload() {
    // Always allow full data or survey-only options
    if (_selectedOption == LocationSharingOption.fullData || 
        _selectedOption == LocationSharingOption.surveyOnly) {
      return true;
    }
    
    // For partial data, always allow (even if no clusters selected - equivalent to survey-only)
    if (_selectedOption == LocationSharingOption.partialData) {
      return true;
    }
    
    return false;
  }

  Widget _buildLocationClusterSelection() {
    if (_dataSummary?.locationClusters.isEmpty ?? true) {
      return Container(
        margin: EdgeInsets.only(left: 16, right: 16, top: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Text(
          'No location clusters available for selection.',
          style: TextStyle(color: Colors.orange[800]),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Select Location Areas to Share',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'All location areas are selected by default. Uncheck any areas you prefer to keep private:',
            style: TextStyle(fontSize: 13, color: Colors.blue[800]),
          ),
          if (_selectedClusterIds.isEmpty)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have unchecked all areas. This means no location data will be shared (survey responses only).',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12),
          
          // Location cluster checkboxes
          Column(
            children: _dataSummary!.locationClusters.asMap().entries.map((entry) {
              final index = entry.key;
              final cluster = entry.value;
              final clusterId = 'cluster_$index';
              final isSelected = _selectedClusterIds.contains(clusterId);

              return CheckboxListTile(
                title: Text(
                  cluster.areaName,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${cluster.trackCount} location records'),
                    Text(
                      'Visited: ${_formatDate(cluster.firstVisit)} - ${_formatDate(cluster.lastVisit)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedClusterIds.add(clusterId);
                    } else {
                      _selectedClusterIds.remove(clusterId);
                    }
                  });
                },
                activeColor: SouthAfricanTheme.primaryBlue,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }).toList(),
          ),
          
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedClusterIds.isEmpty 
                        ? 'No location areas selected (survey responses only)'
                        : 'Sharing: ${_selectedClusterIds.length} of ${_dataSummary!.locationClusters.length} location areas',
                    style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
