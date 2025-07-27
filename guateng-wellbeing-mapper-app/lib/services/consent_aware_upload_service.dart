import 'package:flutter/material.dart';
import '../models/data_sharing_consent.dart';
import '../services/data_upload_service.dart';
import '../services/wellbeing_survey_service.dart';
import '../db/survey_database.dart';
import '../ui/data_sharing_consent_dialog.dart';

/// Enhanced data upload service that respects user's data sharing preferences
class ConsentAwareDataUploadService {
  /// Upload data with user consent dialog for research participants
  static Future<void> uploadWithConsent({
    required BuildContext context,
    required String participantUuid,
    required String researchSite,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Show consent dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DataSharingConsentDialog(
          participantUuid: participantUuid,
          researchSite: researchSite,
          onUploadProceed: () async {
            await _executeUploadWithConsent(
              participantUuid: participantUuid,
              researchSite: researchSite,
              onSuccess: onSuccess,
              onError: onError,
            );
          },
          onUploadCancelled: () {
            onError('Upload cancelled by user');
          },
        ),
      );
    } catch (e) {
      onError('Error showing consent dialog: $e');
    }
  }

  /// Execute the upload based on user's consent preferences
  static Future<void> _executeUploadWithConsent({
    required String participantUuid,
    required String researchSite,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final db = SurveyDatabase();
      
      // Get user's latest consent decision
      final consent = await db.getLatestDataSharingConsent(participantUuid);
      if (consent == null) {
        onError('No consent decision found');
        return;
      }

      // Get survey data (always included)
      final initialSurveys = await db.getInitialSurveys();
      final recurringSurveys = await db.getRecurringSurveys();
      final wellbeingSurveys = await WellbeingSurveyService().getUnsyncedWellbeingSurveys();

      // Get location data based on consent
      List<LocationTrack> locationTracks = [];
      
      switch (consent.locationSharingOption) {
        case LocationSharingOption.fullData:
          locationTracks = await DataUploadService.getRecentLocationTracks();
          break;
          
        case LocationSharingOption.partialData:
          locationTracks = await _getPartialLocationData(consent);
          break;
          
        case LocationSharingOption.surveyOnly:
          locationTracks = []; // No location data
          break;
      }

      // Upload data
      final result = await DataUploadService.uploadParticipantData(
        researchSite: researchSite,
        initialSurveys: initialSurveys,
        recurringSurveys: recurringSurveys,
        wellbeingSurveys: wellbeingSurveys,
        locationTracks: locationTracks,
        participantUuid: participantUuid,
      );

      if (result.success) {
        // Mark upload as completed
        await DataUploadService.markUploadCompleted(researchSite, result.uploadId!);
        
        // Mark wellbeing surveys as synced
        for (final survey in wellbeingSurveys) {
          await WellbeingSurveyService().markAsSynced(survey.id);
        }
        
        onSuccess();
      } else {
        onError('Upload failed: ${result.error}');
      }
    } catch (e) {
      onError('Upload error: $e');
    }
  }

  /// Get filtered location data for partial sharing
  static Future<List<LocationTrack>> _getPartialLocationData(DataSharingConsent consent) async {
    final allTracks = await DataUploadService.getRecentLocationTracks();
    
    if (consent.customLocationIds == null || consent.customLocationIds!.isEmpty) {
      // If no specific locations selected, return empty list
      return [];
    }
    
    // Create location clusters (same logic as in the consent dialog)
    final clusters = _createLocationClusters(allTracks);
    
    // Get the selected cluster indices from the customLocationIds
    final selectedClusters = <LocationCluster>[];
    for (final clusterId in consent.customLocationIds!) {
      if (clusterId.startsWith('cluster_')) {
        final index = int.tryParse(clusterId.substring(8)); // Remove 'cluster_' prefix
        if (index != null && index < clusters.length) {
          selectedClusters.add(clusters[index]);
        }
      }
    }
    
    // Filter tracks that belong to selected clusters
    final filteredTracks = <LocationTrack>[];
    const double clusterRadius = 0.01; // Same radius used in clustering
    
    for (final track in allTracks) {
      for (final cluster in selectedClusters) {
        final distance = _calculateDistance(
          track.latitude, track.longitude,
          cluster.centerLatitude, cluster.centerLongitude,
        );
        
        if (distance <= clusterRadius) {
          filteredTracks.add(track);
          break; // Track belongs to this cluster, no need to check others
        }
      }
    }
    
    return filteredTracks;
  }

  /// Create location clusters (duplicate from dialog for filtering)
  static List<LocationCluster> _createLocationClusters(List<LocationTrack> tracks) {
    if (tracks.isEmpty) return [];
    
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
          // Add to existing cluster
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

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple Euclidean distance approximation for clustering
    return ((lat1 - lat2).abs() + (lon1 - lon2).abs());
  }

  static String _getAreaName(double latitude, double longitude) {
    // Simple area naming based on coordinates (could be enhanced with reverse geocoding)
    return "Area ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}";
  }

  /// Get summary of what data would be uploaded based on consent
  static Future<Map<String, dynamic>> getUploadSummary({
    required String participantUuid,
    required LocationSharingOption sharingOption,
  }) async {
    final db = SurveyDatabase();
    
    // Get survey counts
    final initialSurveys = await db.getInitialSurveys();
    final recurringSurveys = await db.getRecurringSurveys();
    final wellbeingSurveys = await WellbeingSurveyService().getUnsyncedWellbeingSurveys();
    
    // Get location count based on sharing option
    int locationCount = 0;
    switch (sharingOption) {
      case LocationSharingOption.fullData:
        final tracks = await DataUploadService.getRecentLocationTracks();
        locationCount = tracks.length;
        break;
      case LocationSharingOption.partialData:
        // Would calculate based on user's selection
        locationCount = 0; // Placeholder
        break;
      case LocationSharingOption.surveyOnly:
        locationCount = 0;
        break;
    }
    
    return {
      'initialSurveyCount': initialSurveys.length,
      'recurringSurveyCount': recurringSurveys.length,
      'wellbeingSurveyCount': wellbeingSurveys.length,
      'locationTrackCount': locationCount,
      'sharingOption': sharingOption.toString().split('.').last,
    };
  }

  /// Check if user needs to provide new consent (e.g., after significant time has passed)
  static Future<bool> needsNewConsent(String participantUuid) async {
    final db = SurveyDatabase();
    final latestConsent = await db.getLatestDataSharingConsent(participantUuid);
    
    if (latestConsent == null) {
      return true; // No previous consent
    }
    
    // Check if consent is older than 30 days
    final consentAge = DateTime.now().difference(latestConsent.decisionTimestamp);
    return consentAge.inDays > 30;
  }

  /// Get user's current consent preferences
  static Future<LocationSharingOption?> getCurrentConsentPreference(String participantUuid) async {
    final db = SurveyDatabase();
    final latestConsent = await db.getLatestDataSharingConsent(participantUuid);
    return latestConsent?.locationSharingOption;
  }
}
