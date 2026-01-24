import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'dart:io' show Platform;
import '../models/journal_entry.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  FirebaseAnalytics? _analytics;

  AnalyticsService._init();

  Future<void> initialize() async {
    if (kIsWeb ||
        (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
      debugPrint('Firebase Analytics not available on desktop/web platforms');
      _analytics = null;
      return;
    }
    try {
      _analytics = FirebaseAnalytics.instance;
      debugPrint('Firebase Analytics initialized successfully');
      debugPrint('Analytics service is ready to track events');

      try {
        await _analytics!.logEvent(name: 'app_opened');
        await _analytics!.logAppOpen();
        debugPrint('App opened event sent successfully');
      } catch (e) {
        debugPrint('Could not send app opened event: $e');
      }
    } catch (e) {
      debugPrint('Firebase Analytics initialization failed: $e');
      debugPrint('Analytics events will not be tracked');
      _analytics = null;
    }
  }

  bool get isConnected {
    try {
      return _analytics != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> logScreenView(String screenName) async {
    if (_analytics != null) {
      await _analytics!.logScreenView(screenName: screenName);
    }
  }

  Future<void> logJournalEntryCreated({
    required Mood mood,
    bool? hasLocation,
  }) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: 'journal_entry_created',
        parameters: {
          'mood': mood.label,
          'mood_value': mood.value,
          'has_location': hasLocation ?? false,
        },
      );
    }
  }

  Future<void> logJournalEntryUpdated() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'journal_entry_updated');
    }
  }

  Future<void> logJournalEntryDeleted() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'journal_entry_deleted');
    }
  }

  Future<void> logNotificationScheduled() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'notification_scheduled');
    }
  }

  Future<void> logLocationAccessed() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'location_accessed');
    }
  }

  Future<void> logMoodSelected(Mood mood) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: 'mood_selected',
        parameters: {
          'mood': mood.label,
          'mood_value': mood.value,
        },
      );
    }
  }

  Future<void> logDatePickerOpened() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'date_picker_opened');
    }
  }

  Future<void> logTimePickerOpened() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'time_picker_opened');
    }
  }

  Future<void> logJournalEntryViewed(int entryId) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: 'journal_entry_viewed',
        parameters: {'entry_id': entryId},
      );
    }
  }

  Future<void> logChartViewed(String chartType) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: 'chart_viewed',
        parameters: {'chart_type': chartType},
      );
    }
  }

  Future<void> logSaveButtonClicked(String screenName) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: 'save_button_clicked',
        parameters: {'screen': screenName},
      );
    }
  }

  Future<void> logEntryDiscarded() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'entry_discarded');
    }
  }

  Future<void> logNotificationTested() async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: 'notification_tested');
    }
  }

  FirebaseAnalytics? get analytics => _analytics;
}
