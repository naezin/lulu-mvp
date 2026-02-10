import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/baby_model.dart';
import '../constants/ai_prompts.dart';

/// OpenAI API service
/// Preterm/multiple births specialized AI parenting assistant
class OpenAIService {
  static bool _initialized = false;

  /// Initialize OpenAI
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

  /// Check initialization status
  static bool get isInitialized => _initialized;

  // ========================================
  // 1. AI Baby Advice
  // ========================================

  /// Baby info based personalized parenting advice
  static Future<OpenAIResponse> getBabyAdvice({
    required BabyModel baby,
    required String question,
  }) async {
    if (!_initialized) {
      return OpenAIResponse.error(AiPrompts.errorAiDisabled);
    }

    try {
      final babyContext = _buildBabyContext(baby);

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                AiPrompts.systemPrompt,
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                AiPrompts.buildBabyQuestionPrompt(
                  babyContext: babyContext,
                  question: question,
                ),
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
      debugPrint('[OpenAI] Error getting advice: $e');
      return OpenAIResponse.error('${AiPrompts.errorAdviceFailed}: $e');
    }
  }

  // ========================================
  // 2. Sweet Spot Interpretation
  // ========================================

  /// Explain Sweet Spot status to parents
  static Future<OpenAIResponse> interpretSweetSpot({
    required String currentState,
    required int minutesUntilSweetSpot,
    required int babyAgeMonths,
    bool isPreterm = false,
  }) async {
    if (!_initialized) {
      return OpenAIResponse.error(AiPrompts.errorAiDisabled);
    }

    try {
      final stateDescription = switch (currentState) {
        'too_early' => AiPrompts.sweetSpotTooEarly,
        'approaching' => AiPrompts.sweetSpotApproaching,
        'optimal' => AiPrompts.sweetSpotOptimal,
        'overtired' => AiPrompts.sweetSpotOvertired,
        _ => AiPrompts.sweetSpotUnknown,
      };

      final prompt = AiPrompts.buildSweetSpotPrompt(
        babyAgeMonths: babyAgeMonths,
        isPreterm: isPreterm,
        stateDescription: stateDescription,
        minutesUntilSweetSpot: minutesUntilSweetSpot,
      );

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                AiPrompts.systemPrompt,
              ),
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
      debugPrint('[OpenAI] Error interpreting sweet spot: $e');
      return OpenAIResponse.error(AiPrompts.errorSweetSpotFailed);
    }
  }

  // ========================================
  // 3. Multiple Births Tips
  // ========================================

  /// Provide tips for multiple births families
  static Future<OpenAIResponse> getMultipleBirthsTip({
    required int babyCount,
    required String situation,
    List<String>? babyNames,
  }) async {
    if (!_initialized) {
      return OpenAIResponse.error(AiPrompts.errorAiDisabled);
    }

    try {
      final babyType = AiPrompts.getMultipleBirthLabel(babyCount);
      final situationText = AiPrompts.getSituationLabel(situation);

      final prompt = AiPrompts.buildMultipleBirthsTipPrompt(
        babyType: babyType,
        situationText: situationText,
        babyNames: babyNames,
      );

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                AiPrompts.systemPrompt,
              ),
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
      debugPrint('[OpenAI] Error getting multiples tip: $e');
      return OpenAIResponse.error(AiPrompts.errorMultiplesTipFailed);
    }
  }

  // ========================================
  // Private Helpers
  // ========================================

  /// Convert baby info to context string
  static String _buildBabyContext(BabyModel baby) {
    final buffer = StringBuffer();

    buffer.writeln('- ${AiPrompts.labelName}: ${baby.name}');

    if (baby.isPreterm && baby.correctedAgeInMonths != null) {
      buffer.writeln(
        '- ${AiPrompts.labelCorrectedAge}: '
        '${baby.correctedAgeInMonths}${AiPrompts.unitMonths}',
      );
      buffer.writeln(
        '- ${AiPrompts.labelActualAge}: '
        '${baby.actualAgeInMonths}${AiPrompts.unitMonths}',
      );
      buffer.writeln(
        '- ${AiPrompts.labelGestationalWeeks}: '
        '${baby.gestationalWeeksAtBirth}${AiPrompts.unitWeeks} '
        '(${AiPrompts.labelPretermSuffix})',
      );
    } else {
      buffer.writeln(
        '- ${AiPrompts.labelAge}: '
        '${baby.actualAgeInMonths}${AiPrompts.unitMonths}',
      );
    }

    if (baby.isMultipleBirth) {
      buffer.writeln(
        '- ${AiPrompts.labelMultipleBirth}: '
        '${baby.multipleBirthType?.value ?? ""}',
      );
      if (baby.birthOrder != null) {
        buffer.writeln(
          '- ${AiPrompts.labelBirthOrder}: '
          '${baby.birthOrder}${AiPrompts.unitOrdinalSuffix}',
        );
      }
    }

    return buffer.toString();
  }
}

/// OpenAI response wrapper
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
