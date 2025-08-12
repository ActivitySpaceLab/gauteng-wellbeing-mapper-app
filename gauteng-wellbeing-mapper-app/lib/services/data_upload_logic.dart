import 'package:shared_preferences/shared_preferences.dart';

/// A class containing pure, testable logic for the data upload service.
class DataUploadLogic {
  /// Check if participant should upload data (every two weeks).
  static bool shouldUploadData(
      {required SharedPreferences prefs, required String researchSite}) {
    try {
      final lastUploadKey = 'last_upload_$researchSite';
      final lastUploadTimestamp = prefs.getInt(lastUploadKey);

      if (lastUploadTimestamp == null) {
        return true; // First upload
      }

      final lastUpload =
          DateTime.fromMillisecondsSinceEpoch(lastUploadTimestamp);
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

      return lastUpload.isBefore(twoWeeksAgo);
    } catch (e) {
      return false;
    }
  }

  /// Validates if the research site is known.
  static bool isKnownResearchSite(
      {required String researchSite,
      required Map<String, dynamic> serverConfigs}) {
    return serverConfigs.containsKey(researchSite);
  }
}
