import 'package:intl/intl.dart';

import '../../constants/import_strings.dart';
import 'parsed_activity.dart';

/// BabyTime activity TXT file parser
///
/// Parses activity_*.txt files exported from BabyTime app.
///
/// Supported record types:
/// - formula, breast milk, pumped → feeding
/// - nap, night sleep → sleep
/// - diaper → diaper
/// - play, tummy time, bath, outing → play
/// - temperature, medication → health
///
/// File format example:
/// ```
/// 2026-01-06 06:14 AM
/// 기록 종류: 분유
/// 분유 총 양(ml): 100 (ml)
/// ====================
/// ```
class BabytimeParser {
  // Block separator (=====)
  static final _blockSeparator = RegExp(r'={10,}');

  // Time range pattern (sleep etc.)
  // e.g.: 2026-01-06 01:40 AM ~ 2026-01-06 06:14 AM
  static final _timeRangePattern = RegExp(
    r'(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s*[AP]M)\s*~\s*(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s*[AP]M)',
    caseSensitive: false,
  );

  // Single time pattern
  // e.g.: 2026-01-06 06:14 AM
  static final _singleTimePattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s*[AP]M)\s*$',
    caseSensitive: false,
  );

  // Date formats (AM/PM)
  static final _dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
  static final _dateFormatNoSpace = DateFormat('yyyy-MM-dd h:mm a');

  /// Parse TXT file content
  ///
  /// [content] TXT file content
  /// Returns list of parsed activities
  Future<List<ParsedActivity>> parse(String content) async {
    final activities = <ParsedActivity>[];

    // Split by blocks
    final blocks = content.split(_blockSeparator);

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      try {
        final activity = _parseBlock(trimmed);
        if (activity != null) {
          activities.add(activity);
        }
      } catch (e) {
        // Skip failed blocks
        continue;
      }
    }

    return activities;
  }

  /// Parse single block
  ParsedActivity? _parseBlock(String block) {
    final lines =
        block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // 1. Parse time (first line)
    DateTime? startTime;
    DateTime? endTime;

    final firstLine = lines[0];

    // Check time range (sleep etc.)
    final timeRangeMatch = _timeRangePattern.firstMatch(firstLine);
    if (timeRangeMatch != null) {
      startTime = _parseTime(timeRangeMatch.group(1)!);
      endTime = _parseTime(timeRangeMatch.group(2)!);
    } else {
      // Check single time
      final singleTimeMatch = _singleTimePattern.firstMatch(firstLine);
      if (singleTimeMatch != null) {
        startTime = _parseTime(singleTimeMatch.group(1)!);
      }
    }

    if (startTime == null) return null;

    // 2. Parse record type
    String? recordType;
    for (final line in lines) {
      if (line.startsWith(ImportStrings.recordTypePrefix) ||
          line.startsWith(ImportStrings.recordTypePrefixNoSpace)) {
        recordType = line.replaceFirst(ImportStrings.recordTypeRegex, '').trim();
        break;
      }
    }

    if (recordType == null) return null;

    // 3. Map to LULU ActivityType
    final activityType = ImportStrings.mapActivityType(recordType);
    if (activityType == null) return null;

    // 4. Parse details
    final data = <String, dynamic>{};
    String? notes;

    for (final line in lines) {
      // Formula amount
      if (line.contains(ImportStrings.formula) &&
          line.contains(ImportStrings.unitMl)) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['amount_ml'] = int.parse(match.group(1)!);
          data['feedingType'] = 'bottle';
          data['formulaType'] = 'formula';
        }
      }
      // Breast milk duration
      else if (line.contains(ImportStrings.breastMilk) &&
          (line.contains(ImportStrings.unitHours) ||
              line.contains(ImportStrings.unitMinutes))) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['duration_minutes'] = int.parse(match.group(1)!);
          data['feedingType'] = 'breast';
        }
      }
      // Pumped amount
      else if (line.contains(ImportStrings.pumped) &&
          line.contains(ImportStrings.unitMl)) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['amount_ml'] = int.parse(match.group(1)!);
          data['feedingType'] = 'bottle';
          data['formulaType'] = 'pumped';
        }
      }
      // Bowel type
      else if (line.startsWith(ImportStrings.bowelTypePrefix) ||
          line.startsWith(ImportStrings.bowelTypePrefixNoSpace)) {
        final type = line.replaceFirst(ImportStrings.bowelTypeRegex, '').trim();
        data['wet'] = type.contains(ImportStrings.wet);
        data['dirty'] = type.contains(ImportStrings.dirty);
      }
      // Stool color (HEX code)
      else if (line.startsWith(ImportStrings.stoolColorPrefix)) {
        final color = line.replaceFirst(ImportStrings.stoolColorPrefix, '').trim();
        if (color.isNotEmpty) {
          data['stoolColor'] = color;
        }
      }
      // Duration (sleep)
      else if (line.startsWith(ImportStrings.durationPrefix) ||
          line.contains(ImportStrings.durationKeyword)) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['duration_minutes'] = int.parse(match.group(1)!);
        }
      }
      // Memo
      else if (line.startsWith(ImportStrings.memoPrefix)) {
        notes = line.replaceFirst(ImportStrings.memoPrefix, '').trim();
        if (notes.isEmpty) notes = null;
      }
    }

    // 5. Determine sleep type (nap/night)
    if (activityType == 'sleep') {
      data['sleepType'] = ImportStrings.getSleepType(recordType);
    }

    // 6. Determine play type
    if (activityType == 'play') {
      data['playType'] = ImportStrings.getPlayType(recordType);
    }

    // 7. Determine health type
    if (activityType == 'health') {
      // temperature/medication etc.
    }

    return ParsedActivity(
      type: activityType,
      startTime: startTime,
      endTime: endTime,
      data: data,
      notes: notes,
      source: 'babytime',
    );
  }

  /// Parse time string
  DateTime? _parseTime(String timeStr) {
    try {
      // Normalize whitespace
      final normalized = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Try AM/PM format
      try {
        return _dateFormat.parse(normalized);
      } catch (_) {} // Silent: try next format

      // Try alternative format
      try {
        return _dateFormatNoSpace.parse(normalized);
      } catch (_) {} // Silent: try next format

      // Try ISO format
      return DateTime.tryParse(normalized);
    } catch (e) {
      return null;
    }
  }
}
