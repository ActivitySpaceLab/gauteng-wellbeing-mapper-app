import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/services/data_upload_logic.dart';

void main() {
  group('DataUploadLogic', () {
    test('shouldUploadData returns true on first run', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final result =
          DataUploadLogic.shouldUploadData(prefs: prefs, researchSite: 'gauteng');
      expect(result, isTrue);
    });

    test('shouldUploadData returns false if last upload was recent', () async {
      final now = DateTime.now();
      final lastUpload = now.subtract(const Duration(days: 7));
      SharedPreferences.setMockInitialValues({
        'last_upload_gauteng': lastUpload.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final result =
          DataUploadLogic.shouldUploadData(prefs: prefs, researchSite: 'gauteng');
      expect(result, isFalse);
    });

    test('shouldUploadData returns true if last upload was long ago', () async {
      final now = DateTime.now();
      final lastUpload = now.subtract(const Duration(days: 15));
      SharedPreferences.setMockInitialValues({
        'last_upload_gauteng': lastUpload.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final result =
          DataUploadLogic.shouldUploadData(prefs: prefs, researchSite: 'gauteng');
      expect(result, isTrue);
    });

    test('isKnownResearchSite returns true for known site', () {
      final serverConfigs = {'gauteng': {}};
      final result = DataUploadLogic.isKnownResearchSite(
          researchSite: 'gauteng', serverConfigs: serverConfigs);
      expect(result, isTrue);
    });

    test('isKnownResearchSite returns false for unknown site', () {
      final serverConfigs = {'gauteng': {}};
      final result = DataUploadLogic.isKnownResearchSite(
          researchSite: 'unknown', serverConfigs: serverConfigs);
      expect(result, isFalse);
    });
  });
}
