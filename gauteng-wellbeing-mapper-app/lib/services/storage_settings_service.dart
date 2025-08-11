import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter/foundation.dart';
import '../db/survey_database.dart';

class StorageSettingsService {
  // Default values
  static const int DEFAULT_LOCATION_RETENTION_DAYS = 30;
  static const int DEFAULT_MAP_DISPLAY_DAYS = 14;
  static const int DEFAULT_MAX_MAP_MARKERS = 500;
  static const bool DEFAULT_AUTO_CLEANUP_ENABLED = true;
  
  // SharedPreferences keys
  static const String PREF_LOCATION_RETENTION_DAYS = 'location_retention_days';
  static const String PREF_MAP_DISPLAY_DAYS = 'map_display_days';
  static const String PREF_MAX_MAP_MARKERS = 'max_map_markers';
  static const String PREF_AUTO_CLEANUP_ENABLED = 'auto_cleanup_enabled';
  static const String PREF_LAST_CLEANUP_DATE = 'last_cleanup_date';

  /// Get how many days to retain location data in local storage
  static Future<int> getLocationRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_LOCATION_RETENTION_DAYS) ?? DEFAULT_LOCATION_RETENTION_DAYS;
  }

  /// Set how many days to retain location data in local storage
  static Future<void> setLocationRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_LOCATION_RETENTION_DAYS, days);
    
    // Update Background Geolocation plugin setting
    if (!kIsWeb) {
      await bg.BackgroundGeolocation.setConfig(bg.Config(
        maxDaysToPersist: days
      ));
    }
  }

  /// Get how many days of location data to display on map
  static Future<int> getMapDisplayDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_MAP_DISPLAY_DAYS) ?? DEFAULT_MAP_DISPLAY_DAYS;
  }

  /// Set how many days of location data to display on map
  static Future<void> setMapDisplayDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_MAP_DISPLAY_DAYS, days);
  }

  /// Get maximum number of markers to display on map
  static Future<int> getMaxMapMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_MAX_MAP_MARKERS) ?? DEFAULT_MAX_MAP_MARKERS;
  }

  /// Set maximum number of markers to display on map
  static Future<void> setMaxMapMarkers(int maxMarkers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_MAX_MAP_MARKERS, maxMarkers);
  }

  /// Get whether automatic cleanup is enabled
  static Future<bool> getAutoCleanupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_AUTO_CLEANUP_ENABLED) ?? DEFAULT_AUTO_CLEANUP_ENABLED;
  }

  /// Set whether automatic cleanup is enabled
  static Future<void> setAutoCleanupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_AUTO_CLEANUP_ENABLED, enabled);
  }

  /// Get last cleanup date
  static Future<DateTime?> getLastCleanupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(PREF_LAST_CLEANUP_DATE);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Set last cleanup date
  static Future<void> setLastCleanupDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_LAST_CLEANUP_DATE, date.millisecondsSinceEpoch);
  }

  /// Perform automatic cleanup if needed (daily check)
  static Future<void> performAutoCleanupIfNeeded() async {
    final autoCleanupEnabled = await getAutoCleanupEnabled();
    if (!autoCleanupEnabled) return;

    final lastCleanup = await getLastCleanupDate();
    final now = DateTime.now();
    
    // Only run cleanup once per day
    if (lastCleanup != null && now.difference(lastCleanup).inDays < 1) {
      return;
    }

    await performCleanup();
    await setLastCleanupDate(now);
  }

  /// Perform cleanup of old location data
  static Future<void> performCleanup() async {
    final retentionDays = await getLocationRetentionDays();
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    print('[StorageSettingsService] Performing cleanup - removing data older than $retentionDays days');
    
    try {
      // Clean up background geolocation plugin data
      if (!kIsWeb) {
        final allLocations = await bg.BackgroundGeolocation.locations;
        int removedCount = 0;
        
        for (var location in allLocations) {
          final locationDate = DateTime.fromMillisecondsSinceEpoch(
            (location['timestamp'] as num).toInt()
          );
          
          if (locationDate.isBefore(cutoffDate)) {
            await bg.BackgroundGeolocation.destroyLocation(location['uuid']);
            removedCount++;
          }
        }
        
        print('[StorageSettingsService] Removed $removedCount old location records from plugin storage');
      }
      
      // Clean up database location data
      final database = SurveyDatabase();
      await database.cleanupOldLocationData(cutoffDate);
      
    } catch (e) {
      print('[StorageSettingsService] Error during cleanup: $e');
    }
  }

  /// Get filtered location data for map display
  static Future<List<dynamic>> getFilteredLocationDataForMap() async {
    if (kIsWeb) return [];
    
    final displayDays = await getMapDisplayDays();
    final maxMarkers = await getMaxMapMarkers();
    final cutoffDate = DateTime.now().subtract(Duration(days: displayDays));
    
    try {
      final allLocations = await bg.BackgroundGeolocation.locations;
      
      // Filter by date
      final recentLocations = allLocations.where((location) {
        final locationDate = DateTime.fromMillisecondsSinceEpoch(
          (location['timestamp'] as num).toInt()
        );
        return locationDate.isAfter(cutoffDate);
      }).toList();
      
      // Sort by timestamp (newest first)
      recentLocations.sort((a, b) => 
        (b['timestamp'] as num).compareTo(a['timestamp'] as num));
      
      // Limit to max markers
      if (recentLocations.length > maxMarkers) {
        return recentLocations.take(maxMarkers).toList();
      }
      
      return recentLocations;
      
    } catch (e) {
      print('[StorageSettingsService] Error getting filtered location data: $e');
      return [];
    }
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final stats = <String, dynamic>{};
      
      if (!kIsWeb) {
        final allLocations = await bg.BackgroundGeolocation.locations;
        stats['totalLocations'] = allLocations.length;
        
        if (allLocations.isNotEmpty) {
          final timestamps = allLocations.map((loc) => 
            (loc['timestamp'] as num).toInt()).toList();
          timestamps.sort();
          
          final oldestDate = DateTime.fromMillisecondsSinceEpoch(timestamps.first);
          final newestDate = DateTime.fromMillisecondsSinceEpoch(timestamps.last);
          
          stats['oldestDate'] = oldestDate;
          stats['newestDate'] = newestDate;
          stats['dataSpanDays'] = newestDate.difference(oldestDate).inDays;
        }
      } else {
        stats['totalLocations'] = 0;
      }
      
      // Add database stats
      final database = SurveyDatabase();
      final dbStats = await database.getLocationDataStats();
      stats.addAll(dbStats);
      
      return stats;
      
    } catch (e) {
      print('[StorageSettingsService] Error getting storage stats: $e');
      return {'totalLocations': 0, 'error': e.toString()};
    }
  }
}
