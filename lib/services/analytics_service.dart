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

      await _analytics!.setAnalyticsCollectionEnabled(true);

      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      await _analytics!.setUserId(id: userId);

      await _analytics!.setUserProperty(name: 'app_version', value: '2.0.0');
      await _analytics!.setUserProperty(
          name: 'platform', value: Platform.isAndroid ? 'android' : 'ios');

      debugPrint('Firebase Analytics initialized successfully');
      debugPrint('Analytics service is ready to track events');
      debugPrint('User ID set: $userId');
      debugPrint('Analytics collection enabled: true');

      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await _analytics!.logEvent(name: 'app_opened');
        await _analytics!.logAppOpen();
        debugPrint('App opened event sent successfully');

        await Future.delayed(const Duration(milliseconds: 100));

        await _analytics!.logEvent(
          name: 'first_open',
          parameters: {
            'user_id': userId,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          },
        );
        debugPrint('First open event sent successfully');
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
      try {
        await _analytics!.logScreenView(screenName: screenName);
        debugPrint('Screen view logged: $screenName');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    } else {
      debugPrint('Analytics not available - cannot log screen view');
    }
  }

  Future<void> logSessionStart() async {
    if (_analytics != null) {
      try {
        await _analytics!.logEvent(name: 'session_start');
      } catch (e) {
        debugPrint('Error logging session start: $e');
      }
    }
  }

  Future<void> logJournalEntryCreated({
    required Mood mood,
    bool? hasLocation,
  }) async {
    if (_analytics != null) {
      try {
        await _analytics!.logEvent(
          name: 'journal_entry_created',
          parameters: {
            'mood': mood.label,
            'mood_value': mood.value,
            'has_location': hasLocation ?? false,
          },
        );
        debugPrint('Journal entry created event logged');
      } catch (e) {
        debugPrint('Error logging journal entry created: $e');
      }
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

  Future<void> testAnalytics() async {
    if (_analytics != null) {
      try {
        await _analytics!.logEvent(
          name: 'analytics_test',
          parameters: {
            'timestamp': DateTime.now().toIso8601String(),
            'test': true,
          },
        );
        debugPrint('Test analytics event sent');
      } catch (e) {
        debugPrint('Error sending test analytics event: $e');
      }
    } else {
      debugPrint('Analytics not initialized - cannot send test event');
    }
  }

  FirebaseAnalytics? get analytics => _analytics;
}
