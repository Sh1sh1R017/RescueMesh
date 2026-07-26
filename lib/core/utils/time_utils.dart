/// Shared time-formatting utilities used across Dashboard, Feed, and Map screens.
library;

/// Returns a human-readable relative time string from an epoch-millisecond timestamp.
///
/// Examples: "3m ago", "2h ago", "Just now"
String relativeTime(int timestampMs) {
  final diff = DateTime.now()
      .difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
