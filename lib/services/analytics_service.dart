import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/journal_entry.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  FirebaseAnalytics? _analytics;

  AnalyticsService._init();

  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      debugPrint('Firebase Analytics initialized successfully');
      debugPrint('Analytics service is ready to track events');
      
      try {
        await _analytics!.logEvent(name: 'app_opened');
        debugPrint('Test analytics event sent successfully');
      } catch (e) {
        debugPrint('Could not send test event: $e');
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

  FirebaseAnalytics? get analytics => _analytics;
}
