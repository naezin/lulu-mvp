import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/baby_model.dart';

/// OpenAI API 서비스
/// 조산아/다태아 전문 AI 육아 도우미
class OpenAIService {
  static bool _initialized = false;

  /// 시스템 프롬프트 (한국어)
  static const String _systemPrompt = '''
당신은 조산아와 다태아 전문 AI 육아 도우미입니다.

## 역할
- 신생아와 영아의 수면, 수유, 발달에 대한 조언 제공
- 조산아의 교정연령 기준 발달 조언
- 다태아 가정의 특수한 상황 이해와 맞춤 조언

## 원칙
1. **교정연령 기준**: 조산아는 항상 교정연령 기준으로 발달을 평가합니다
2. **비교 금지**: 쌍둥이나 다태아 간 비교하지 않습니다. "우열", "더 빠른/느린" 표현을 사용하지 않습니다
3. **의료 진단 금지**: 의학적 진단이나 처방을 하지 않습니다. 걱정되는 증상은 의료진 상담을 권유합니다
4. **공감과 격려**: 부모의 노력을 인정하고, 따뜻하고 공감하는 톤으로 대화합니다
5. **실용적 조언**: 구체적이고 바로 실행 가능한 팁을 제공합니다

## 응답 형식
- 간결하고 명확하게 (200자 이내 권장)
- 이모지 적절히 사용
- 필요시 단계별 목록 제공
''';

  /// OpenAI 초기화
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[WARN] OpenAI already initialized');
      return;
    }

    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty || apiKey == 'your-openai-api-key') {
      debugPrint('[WARN] OpenAI API key not configured - AI features disabled');
      return;
    }

    OpenAI.apiKey = apiKey;
    _initialized = true;
    debugPrint('[OK] OpenAI initialized successfully');
  }

  /// 초기화 여부 확인
  static bool get isInitialized => _initialized;

  // ========================================
  // 1. AI 육아 조언
  // ========================================

  /// 아기 정보 기반 맞춤 육아 조언
  static Future<OpenAIResponse> getBabyAdvice({
    required BabyModel baby,
    required String question,
  }) async {
    if (!_initialized) {
      return OpenAIResponse.error('AI 기능이 비활성화되어 있습니다.');
    }

    try {
      final babyContext = _buildBabyContext(baby);

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(_systemPrompt),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '아기 정보:\n$babyContext\n\n질문: $question',
              ),
            ],
          ),
        ],
        maxTokens: 500,
        temperature: 0.7,
      );

      final content = response.choices.first.message.content?.first.text ?? '';
      final tokens = response.usage.totalTokens;

      debugPrint('[OK] [OpenAI] Advice generated (tokens: $tokens)');

      return OpenAIResponse.success(
        content: content,
        tokensUsed: tokens,
      );
    } catch (e) {
      debugPrint('❌ [OpenAI] Error getting advice: $e');
      return OpenAIResponse.error('AI 조언을 가져오는데 실패했습니다: $e');
    }
  }

  // ========================================
  // 2. Sweet Spot 해석
  // ========================================

  /// Sweet Spot 상태를 부모에게 쉽게 설명
  static Future<OpenAIResponse> interpretSweetSpot({
    required String currentState, // 'too_early', 'approaching', 'optimal', 'overtired'
    required int minutesUntilSweetSpot,
    required int babyAgeMonths,
    bool isPreterm = false,
  }) async {
    if (!_initialized) {
      return OpenAIResponse.error('AI 기능이 비활성화되어 있습니다.');
    }

    try {
      final stateDescription = switch (currentState) {
        'too_early' => '아직 피곤하지 않은 상태',
        'approaching' => '곧 적정 수면 시간에 접근',
        'optimal' => '지금이 재우기 최적의 시간',
        'overtired' => '과로 상태 - 즉시 재우기 필요',
        _ => '상태 확인 중',
      };

      final prompt = '''
아기 정보:
- 나이: $babyAgeMonths개월${isPreterm ? ' (교정연령)' : ''}
- 현재 상태: $stateDescription
- Sweet Spot까지: $minutesUntilSweetSpot분

부모에게 현재 상황을 간단히 설명하고, 어떻게 해야 하는지 조언해주세요.
2-3문장으로 짧게 답변해주세요.
''';

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(_systemPrompt),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
        maxTokens: 200,
        temperature: 0.7,
      );

      final content = response.choices.first.message.content?.first.text ?? '';
      final tokens = response.usage.totalTokens;

      return OpenAIResponse.success(
        content: content,
        tokensUsed: tokens,
      );
    } catch (e) {
      debugPrint('❌ [OpenAI] Error interpreting sweet spot: $e');
      return OpenAIResponse.error('Sweet Spot 해석에 실패했습니다.');
    }
  }

  // ========================================
  // 3. 다태아 맞춤 팁
  // ========================================

  /// 다태아 가정 맞춤 팁 제공
  static Future<OpenAIResponse> getMultipleBirthsTip({
    required int babyCount,
    required String situation, // 'feeding', 'sleep', 'diaper', 'general'
    List<String>? babyNames,
  }) async {
    if (!_initialized) {
      return OpenAIResponse.error('AI 기능이 비활성화되어 있습니다.');
    }

    try {
      final babyType = switch (babyCount) {
        2 => '쌍둥이',
        3 => '세쌍둥이',
        4 => '네쌍둥이',
        _ => '다태아',
      };

      final situationText = switch (situation) {
        'feeding' => '수유',
        'sleep' => '수면/재우기',
        'diaper' => '기저귀 교체',
        _ => '전반적인 육아',
      };

      final prompt = '''
$babyType 가정의 $situationText에 대한 실용적인 팁을 알려주세요.
${babyNames != null ? '아기 이름: ${babyNames.join(", ")}' : ''}

- 구체적이고 바로 실행 가능한 팁 2-3개
- 동시에 처리하는 방법 위주
- 부모의 체력 관리도 고려
''';

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(_systemPrompt),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
        maxTokens: 300,
        temperature: 0.7,
      );

      final content = response.choices.first.message.content?.first.text ?? '';
      final tokens = response.usage.totalTokens;

      return OpenAIResponse.success(
        content: content,
        tokensUsed: tokens,
      );
    } catch (e) {
      debugPrint('❌ [OpenAI] Error getting multiples tip: $e');
      return OpenAIResponse.error('다태아 팁을 가져오는데 실패했습니다.');
    }
  }

  // ========================================
  // Private Helpers
  // ========================================

  /// 아기 정보를 컨텍스트 문자열로 변환
  static String _buildBabyContext(BabyModel baby) {
    final buffer = StringBuffer();

    buffer.writeln('- 이름: ${baby.name}');

    if (baby.isPreterm && baby.correctedAgeInMonths != null) {
      buffer.writeln('- 교정연령: ${baby.correctedAgeInMonths}개월');
      buffer.writeln('- 실제연령: ${baby.actualAgeInMonths}개월');
      buffer.writeln('- 출생주수: ${baby.gestationalWeeksAtBirth}주 (조산아)');
    } else {
      buffer.writeln('- 나이: ${baby.actualAgeInMonths}개월');
    }

    if (baby.isMultipleBirth) {
      buffer.writeln('- 다태아: ${baby.multipleBirthType?.label ?? ""}');
      if (baby.birthOrder != null) {
        buffer.writeln('- 출생순서: ${baby.birthOrder}번째');
      }
    }

    return buffer.toString();
  }
}

/// OpenAI 응답 래퍼
class OpenAIResponse {
  final bool isSuccess;
  final String? content;
  final String? errorMessage;
  final int tokensUsed;

  const OpenAIResponse._({
    required this.isSuccess,
    this.content,
    this.errorMessage,
    this.tokensUsed = 0,
  });

  factory OpenAIResponse.success({
    required String content,
    int tokensUsed = 0,
  }) {
    return OpenAIResponse._(
      isSuccess: true,
      content: content,
      tokensUsed: tokensUsed,
    );
  }

  factory OpenAIResponse.error(String message) {
    return OpenAIResponse._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
