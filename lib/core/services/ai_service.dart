import 'package:flutter/foundation.dart';

import '../../data/models/baby_model.dart';
import 'openai_service.dart';
import 'ai_usage_manager.dart';

/// 통합 AI 서비스
/// OpenAI API + 사용량 관리 통합
class AIService {
  final AIUsageManager _usageManager;

  AIService._(this._usageManager);

  /// AI 서비스 생성
  static Future<AIService> create({bool isPremium = false}) async {
    final usageManager = await AIUsageManager.create(isPremium: isPremium);
    return AIService._(usageManager);
  }

  /// AI 기능 사용 가능 여부
  bool get isAvailable => OpenAIService.isInitialized;

  /// 사용량 관리자
  AIUsageManager get usageManager => _usageManager;

  // ========================================
  // 1. AI 육아 조언
  // ========================================

  /// 아기 맞춤 육아 조언 요청
  Future<AIRequestResult<String>> getBabyAdvice({
    required BabyModel baby,
    required String question,
  }) async {
    // AI 초기화 확인
    if (!isAvailable) {
      return AIRequestResult.error('AI 기능이 비활성화되어 있습니다.');
    }

    // 사용량 확인
    if (!await _usageManager.canMakeRequest()) {
      final usage = await _usageManager.getUsageSummary();
      return AIRequestResult.limitReached(usage);
    }

    try {
      // API 요청
      final response = await OpenAIService.getBabyAdvice(
        baby: baby,
        question: question,
      );

      if (response.isSuccess && response.content != null) {
        // 사용량 기록
        await _usageManager.incrementRequestCount();
        await _usageManager.addTokensUsed(response.tokensUsed);

        final usage = await _usageManager.getUsageSummary();
        return AIRequestResult.success(response.content!, usage: usage);
      } else {
        return AIRequestResult.error(
          response.errorMessage ?? 'AI 조언을 가져오는데 실패했습니다.',
        );
      }
    } catch (e) {
      debugPrint('❌ [AIService] Error: $e');
      return AIRequestResult.error('오류가 발생했습니다: $e');
    }
  }

  // ========================================
  // 2. Sweet Spot 해석
  // ========================================

  /// Sweet Spot 상태 해석
  Future<AIRequestResult<String>> interpretSweetSpot({
    required String currentState,
    required int minutesUntilSweetSpot,
    required int babyAgeMonths,
    bool isPreterm = false,
  }) async {
    if (!isAvailable) {
      return AIRequestResult.error('AI 기능이 비활성화되어 있습니다.');
    }

    if (!await _usageManager.canMakeRequest()) {
      final usage = await _usageManager.getUsageSummary();
      return AIRequestResult.limitReached(usage);
    }

    try {
      final response = await OpenAIService.interpretSweetSpot(
        currentState: currentState,
        minutesUntilSweetSpot: minutesUntilSweetSpot,
        babyAgeMonths: babyAgeMonths,
        isPreterm: isPreterm,
      );

      if (response.isSuccess && response.content != null) {
        await _usageManager.incrementRequestCount();
        await _usageManager.addTokensUsed(response.tokensUsed);

        final usage = await _usageManager.getUsageSummary();
        return AIRequestResult.success(response.content!, usage: usage);
      } else {
        return AIRequestResult.error(
          response.errorMessage ?? 'Sweet Spot 해석에 실패했습니다.',
        );
      }
    } catch (e) {
      debugPrint('❌ [AIService] Error: $e');
      return AIRequestResult.error('오류가 발생했습니다: $e');
    }
  }

  // ========================================
  // 3. 다태아 맞춤 팁
  // ========================================

  /// 다태아 맞춤 팁 요청
  Future<AIRequestResult<String>> getMultipleBirthsTip({
    required int babyCount,
    required String situation,
    List<String>? babyNames,
  }) async {
    if (!isAvailable) {
      return AIRequestResult.error('AI 기능이 비활성화되어 있습니다.');
    }

    if (!await _usageManager.canMakeRequest()) {
      final usage = await _usageManager.getUsageSummary();
      return AIRequestResult.limitReached(usage);
    }

    try {
      final response = await OpenAIService.getMultipleBirthsTip(
        babyCount: babyCount,
        situation: situation,
        babyNames: babyNames,
      );

      if (response.isSuccess && response.content != null) {
        await _usageManager.incrementRequestCount();
        await _usageManager.addTokensUsed(response.tokensUsed);

        final usage = await _usageManager.getUsageSummary();
        return AIRequestResult.success(response.content!, usage: usage);
      } else {
        return AIRequestResult.error(
          response.errorMessage ?? '다태아 팁을 가져오는데 실패했습니다.',
        );
      }
    } catch (e) {
      debugPrint('❌ [AIService] Error: $e');
      return AIRequestResult.error('오류가 발생했습니다: $e');
    }
  }

  // ========================================
  // 사용량 조회
  // ========================================

  /// 현재 사용량 조회
  Future<AIUsageSummary> getUsageSummary() => _usageManager.getUsageSummary();

  /// 남은 요청 횟수
  Future<int> getRemainingRequests() => _usageManager.getRemainingRequests();

  /// 요청 가능 여부
  Future<bool> canMakeRequest() => _usageManager.canMakeRequest();
}
