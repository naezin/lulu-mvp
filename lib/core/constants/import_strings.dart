/// BabyTime/Huckleberry 데이터 import 시 매칭에 사용되는 한글 문자열
///
/// import 데이터 포맷 매칭용이므로 i18n 불요 (한글 유지)
/// pre-commit hook 예외 대상
class ImportStrings {
  ImportStrings._();

  // ========================================
  // BabyTime 파서 매칭 문자열
  // ========================================

  /// 기록 종류 라벨
  static const String recordTypePrefix = '기록 종류:';
  static const String recordTypePrefixNoSpace = '기록종류:';
  static final RegExp recordTypeRegex = RegExp(r'기록\s*종류:');

  /// 수유 관련
  static const String formula = '분유';
  static const String breastMilk = '모유';
  static const String pumpedFeeding = '유축수유';
  static const String pumped = '유축';
  static const String feeding = '수유';

  /// 수면 관련
  static const String nap = '낮잠';
  static const String nightSleep = '밤잠';
  static const String sleep = '수면';

  /// 기저귀 관련
  static const String diaper = '기저귀';
  static const String bowelMovement = '배변';
  static const String bowelTypePrefix = '배변 형태:';
  static const String bowelTypePrefixNoSpace = '배변형태:';
  static final RegExp bowelTypeRegex = RegExp(r'배변\s*형태:');
  static const String stoolColorPrefix = '배변색:';
  static const String wet = '소변';
  static const String dirty = '대변';

  /// 놀이 관련
  static const String play = '놀이';
  static const String tummyTime = '터미타임';
  static const String outing = '외출';
  static const String bath = '목욕';

  /// 건강 관련
  static const String temperature = '체온';
  static const String medication = '투약';

  /// 기타 파싱 키워드
  static const String durationPrefix = '소요시간:';
  static const String durationKeyword = '소요시간';
  static const String memoPrefix = '메모:';
  static const String unitMl = 'ml';
  static const String unitMinutes = '분';
  static const String unitHours = '시간';

  /// 기록 종류 → LULU ActivityType 매핑
  static String? mapActivityType(String recordType) {
    switch (recordType) {
      case formula:
      case breastMilk:
      case pumpedFeeding:
      case pumped:
      case feeding:
        return 'feeding';
      case nap:
      case nightSleep:
      case sleep:
        return 'sleep';
      case diaper:
      case bowelMovement:
        return 'diaper';
      case play:
      case tummyTime:
      case outing:
      case bath:
        return 'play';
      case temperature:
      case medication:
        return 'health';
      default:
        return null;
    }
  }

  /// 수면 타입 결정
  static String getSleepType(String recordType) {
    return recordType == nightSleep ? 'night' : 'nap';
  }

  /// 놀이 타입 결정
  static String getPlayType(String recordType) {
    if (recordType == tummyTime) return 'tummyTime';
    if (recordType == bath) return 'bath';
    if (recordType == outing) return 'outdoor';
    return 'play';
  }
}
