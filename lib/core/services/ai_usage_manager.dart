import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 사용량 관리자
/// 일일 요청 제한 및 토큰 사용량 추적
class AIUsageManager {
  static const String _dailyCountKey = 'ai_daily_request_count';
  static const String _dailyDateKey = 'ai_daily_date';
  static const String _totalTokensKey = 'ai_total_tokens';

  /// 무료 사용자 일일 제한
  static const int freeDailyLimit = 10;

  /// 프리미엄 사용자 일일 제한 (무제한)
  static const int premiumDailyLimit = 999999;

  final SharedPreferences _prefs;
  final bool _isPremium;

  AIUsageManager._({
    required SharedPreferences prefs,
    bool isPremium = false,
  })  : _prefs = prefs,
        _isPremium = isPremium;

  /// 인스턴스 생성
  static Future<AIUsageManager> create({bool isPremium = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return AIUsageManager._(prefs: prefs, isPremium: isPremium);
  }

  /// 일일 제한
  int get dailyLimit => _isPremium ? premiumDailyLimit : freeDailyLimit;

  /// 프리미엄 여부
  bool get isPremium => _isPremium;

  // ========================================
  // 일일 요청 카운트
  // ========================================

  /// 오늘 날짜 문자열
  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 저장된 날짜가 오늘인지 확인
  bool _isToday() {
    final savedDate = _prefs.getString(_dailyDateKey);
    return savedDate == _todayString;
  }

  /// 오늘 사용량 초기화 (날짜가 바뀌었을 때)
  Future<void> _resetIfNewDay() async {
    if (!_isToday()) {
      await _prefs.setString(_dailyDateKey, _todayString);
      await _prefs.setInt(_dailyCountKey, 0);
      debugPrint('🔄 [AIUsage] Daily count reset for new day');
    }
  }

  /// 오늘 요청 횟수 조회
  Future<int> getTodayRequestCount() async {
    await _resetIfNewDay();
    return _prefs.getInt(_dailyCountKey) ?? 0;
  }

  /// 남은 요청 횟수 조회
  Future<int> getRemainingRequests() async {
    final used = await getTodayRequestCount();
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  /// 요청 가능 여부 확인
  Future<bool> canMakeRequest() async {
    final remaining = await getRemainingRequests();
    return remaining > 0;
  }

  /// 요청 횟수 증가
  Future<void> incrementRequestCount() async {
    await _resetIfNewDay();
    final current = _prefs.getInt(_dailyCountKey) ?? 0;
    await _prefs.setInt(_dailyCountKey, current + 1);
    debugPrint('📊 [AIUsage] Request count: ${current + 1}/$dailyLimit');
  }

  // ========================================
  // 토큰 사용량 추적
  // ========================================

  /// 총 토큰 사용량 조회
  Future<int> getTotalTokensUsed() async {
    return _prefs.getInt(_totalTokensKey) ?? 0;
  }

  /// 토큰 사용량 추가
  Future<void> addTokensUsed(int tokens) async {
    final current = _prefs.getInt(_totalTokensKey) ?? 0;
    await _prefs.setInt(_totalTokensKey, current + tokens);
    debugPrint('📊 [AIUsage] Total tokens: ${current + tokens}');
  }

  // ========================================
  // 사용량 정보
  // ========================================

  /// 사용량 요약 조회
  Future<AIUsageSummary> getUsageSummary() async {
    final todayCount = await getTodayRequestCount();
    final remaining = await getRemainingRequests();
    final totalTokens = await getTotalTokensUsed();

    return AIUsageSummary(
      todayRequestCount: todayCount,
      remainingRequests: remaining,
      dailyLimit: dailyLimit,
      totalTokensUsed: totalTokens,
      isPremium: _isPremium,
    );
  }

  /// 사용량 초기화 (디버그용)
  Future<void> resetUsage() async {
    await _prefs.remove(_dailyCountKey);
    await _prefs.remove(_dailyDateKey);
    await _prefs.remove(_totalTokensKey);
    debugPrint('🗑️ [AIUsage] Usage data reset');
  }
}

/// AI 사용량 요약
class AIUsageSummary {
  final int todayRequestCount;
  final int remainingRequests;
  final int dailyLimit;
  final int totalTokensUsed;
  final bool isPremium;

  const AIUsageSummary({
    required this.todayRequestCount,
    required this.remainingRequests,
    required this.dailyLimit,
    required this.totalTokensUsed,
    required this.isPremium,
  });

  /// 사용률 (0.0 ~ 1.0)
  double get usageRate => todayRequestCount / dailyLimit;

  /// 제한 초과 여부
  bool get isLimitReached => remainingRequests <= 0;

  /// 거의 소진 여부 (3회 이하 남음)
  bool get isAlmostDepleted => remainingRequests <= 3 && !isPremium;

  @override
  String toString() {
    return 'AIUsageSummary(today: $todayRequestCount/$dailyLimit, '
        'remaining: $remainingRequests, tokens: $totalTokensUsed, '
        'premium: $isPremium)';
  }
}

/// AI 요청 결과 (사용량 관리 포함)
class AIRequestResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final AIUsageSummary? usageSummary;

  const AIRequestResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.usageSummary,
  });

  factory AIRequestResult.success(T data, {AIUsageSummary? usage}) {
    return AIRequestResult._(
      isSuccess: true,
      data: data,
      usageSummary: usage,
    );
  }

  factory AIRequestResult.error(String message, {AIUsageSummary? usage}) {
    return AIRequestResult._(
      isSuccess: false,
      errorMessage: message,
      usageSummary: usage,
    );
  }

  factory AIRequestResult.limitReached(AIUsageSummary usage) {
    return AIRequestResult._(
      isSuccess: false,
      errorMessage: '오늘의 AI 사용량을 모두 소진했습니다. (${usage.dailyLimit}회)',
      usageSummary: usage,
    );
  }
}
