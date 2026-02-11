import 'package:flutter/foundation.dart';

/// Message tier — determines selection priority
enum EncouragementTier {
  /// Data-driven message (highest priority)
  data,

  /// General time-based or fallback message
  general,
}

/// A selected encouragement message ready for display.
///
/// The [key] maps to an ARB key pattern:
///   key="encouragement_dawn_1" + tone="warm" → "encouragementDawnWarm1"
///
/// [params] are substituted into the localized string
/// (e.g. {baby}, {count}, {hours}).
@immutable
class EncouragementMessage {
  /// Base key without tone suffix (e.g. "encouragement_dawn_1")
  final String key;

  /// Whether this is data-driven or general
  final EncouragementTier tier;

  /// Parameters for string interpolation
  final Map<String, String> params;

  const EncouragementMessage({
    required this.key,
    required this.tier,
    this.params = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncouragementMessage &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'EncouragementMessage(key: $key, tier: ${tier.name})';
}
