/// Korean particle (조사) utility for baby names.
///
/// Korean particles change form based on whether the preceding
/// syllable has a final consonant (받침).
///
/// Usage:
/// ```dart
/// KoreanParticle.eulReul('서준')  // → '서준을'
/// KoreanParticle.eulReul('하늘')  // → '하늘을'
/// KoreanParticle.eulReul('조이')  // → '조이를'
/// ```
class KoreanParticle {
  KoreanParticle._();

  /// Check if the last character of [text] has a final consonant (받침).
  static bool _hasBatchim(String text) {
    if (text.isEmpty) return false;
    final lastChar = text.runes.last;
    // Korean syllable Unicode range: AC00-D7A3
    if (lastChar < 0xAC00 || lastChar > 0xD7A3) return false;
    return (lastChar - 0xAC00) % 28 != 0;
  }

  /// Select particle based on final consonant.
  ///
  /// Returns [name] + appropriate particle.
  static String select(
    String name,
    String withBatchim,
    String withoutBatchim,
  ) {
    if (name.isEmpty) return '$name$withoutBatchim';
    final particle = _hasBatchim(name) ? withBatchim : withoutBatchim;
    return '$name$particle';
  }

  // ========================================
  // Convenience methods
  // ========================================

  /// 은/는 (topic marker)
  static String eunNeun(String name) => select(name, '\uC740', '\uB294');

  /// 이/가 (subject marker)
  static String iGa(String name) => select(name, '\uC774', '\uAC00');

  /// 을/를 (object marker)
  static String eulReul(String name) => select(name, '\uC744', '\uB97C');

  /// 과/와 (and/with)
  static String gwaWa(String name) => select(name, '\uACFC', '\uC640');

  /// 아/야 (vocative)
  static String aYa(String name) => select(name, '\uC544', '\uC57C');

  /// 으로/로 (direction/means)
  static String euroRo(String name) => select(name, '\uC73C\uB85C', '\uB85C');

  /// 이를/를 — for baby name + accusative
  ///
  /// In Korean, baby names often get an affectionate 이 suffix
  /// (e.g., "하늘이를", "서준이를"). But names already ending in 이
  /// should not double it (e.g., "조이를" not "조이이를").
  ///
  /// This method handles both cases:
  /// - "서준" → "서준이를" (add 이 suffix + 를)
  /// - "조이" → "조이를" (name ends with 이, just add 를)
  /// - "하늘" → "하늘이를" (add 이 suffix + 를)
  static String iReul(String name) {
    if (name.isEmpty) return name;
    // If name ends with 이 (이 character = U+C774), skip the extra 이
    final lastChar = name.runes.last;
    if (lastChar == 0xC774) {
      return '$name\uB97C'; // 를
    }
    return '$name\uC774\uB97C'; // 이를
  }

  /// 이의/의 — for baby name + possessive with affectionate 이
  static String iUi(String name) {
    if (name.isEmpty) return name;
    final lastChar = name.runes.last;
    if (lastChar == 0xC774) {
      return '$name\uC758'; // 의
    }
    return '$name\uC774\uC758'; // 이의
  }

  /// 이와/와 — for baby name + with/and with affectionate 이
  static String iWa(String name) {
    if (name.isEmpty) return name;
    final lastChar = name.runes.last;
    if (lastChar == 0xC774) {
      return '$name\uC640'; // 와
    }
    return '$name\uC774\uC640'; // 이와
  }

  /// 이도/도 — for baby name + also with affectionate 이
  static String iDo(String name) {
    if (name.isEmpty) return name;
    final lastChar = name.runes.last;
    if (lastChar == 0xC774) {
      return '$name\uB3C4'; // 도
    }
    return '$name\uC774\uB3C4'; // 이도
  }

  /// 이가/가 — for baby name + subject marker with affectionate 이
  static String iGaName(String name) {
    if (name.isEmpty) return name;
    final lastChar = name.runes.last;
    if (lastChar == 0xC774) {
      return '$name\uAC00'; // 가
    }
    return '$name\uC774\uAC00'; // 이가
  }
}
