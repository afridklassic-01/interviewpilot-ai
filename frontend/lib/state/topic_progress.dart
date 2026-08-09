import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lifecycle state of a curriculum topic in the interview progression.
///
/// NOT_STARTED -> IN_PROGRESS (interview started) -> COMPLETED (all 8
/// questions answered). A completed topic is never automatically
/// restarted by "Start Interview".
enum TopicStatus {
  notStarted('Not started'),
  inProgress('In progress'),
  completed('Completed');

  const TopicStatus(this.label);

  final String label;

  String get storageKey => switch (this) {
        TopicStatus.notStarted => 'not_started',
        TopicStatus.inProgress => 'in_progress',
        TopicStatus.completed => 'completed',
      };

  static TopicStatus fromStorage(String value) => switch (value) {
        'in_progress' => TopicStatus.inProgress,
        'completed' => TopicStatus.completed,
        _ => TopicStatus.notStarted,
      };
}

/// Persists per-topic interview progress so it survives navigation,
/// returning to the dashboard, browser refresh and new interviews.
///
/// Storage: shared_preferences (localStorage on Flutter Web). The
/// in-memory map is always the source of truth for the UI and is updated
/// first; persistence is best-effort so tests and offline sessions never
/// crash.
class TopicProgressStore {
  Map<String, TopicStatus> _statuses = {};
  Future<void>? _loading;

  /// Current in-memory statuses (unmodifiable view).
  Map<String, TopicStatus> get statuses => Map.unmodifiable(_statuses);

  TopicStatus statusOf(String topic) =>
      _statuses[topic] ?? TopicStatus.notStarted;

  /// Loads persisted progress once; safe to call repeatedly.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null; // No platform channel (e.g. widget tests): keep in-memory.
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await _prefs();
      if (prefs == null) return;
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _statuses = {
        for (final entry in decoded.entries)
          if (entry.value is String)
            entry.key.toString(): TopicStatus.fromStorage(entry.value as String),
      };
    } catch (_) {
      // Corrupt/legacy data: fall back to fresh in-memory state.
      _statuses = {};
    }
  }

  Future<void> set(String topic, TopicStatus status) async {
    _statuses[topic] = status;
    await _save();
  }

  Future<void> clear() async {
    _statuses = {};
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await _prefs();
      if (prefs == null) return;
      await prefs.setString(
        _storageKey,
        jsonEncode({
          for (final entry in _statuses.entries)
            entry.key: entry.value.storageKey,
        }),
      );
    } catch (_) {
      // Best-effort persistence; the in-memory state is already updated.
    }
  }

  static const String _storageKey = 'interviewpilot.topic_progress.v1';
}
