/// AI 서비스에 전송되는 프롬프트 문자열
///
/// 서버 전송용이므로 i18n 불요 (한글 유지)
/// pre-commit hook 예외 대상
class AiPrompts {
  AiPrompts._();

  /// 시스템 프롬프트 (한국어)
  static const String systemPrompt = '''
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

  /// 아기 컨텍스트 빌드용 라벨
  static const String labelName = '이름';
  static const String labelCorrectedAge = '교정연령';
  static const String labelActualAge = '실제연령';
  static const String labelGestationalWeeks = '출생주수';
  static const String labelPretermSuffix = '조산아';
  static const String labelAge = '나이';
  static const String labelMultipleBirth = '다태아';
  static const String labelBirthOrder = '출생순서';
  static const String unitMonths = '개월';
  static const String unitWeeks = '주';
  static const String unitOrdinalSuffix = '번째';

  /// Sweet Spot 상태 설명
  static const String sweetSpotTooEarly = '아직 피곤하지 않은 상태';
  static const String sweetSpotApproaching = '곧 적정 수면 시간에 접근';
  static const String sweetSpotOptimal = '지금이 재우기 최적의 시간';
  static const String sweetSpotOvertired = '과로 상태 - 즉시 재우기 필요';
  static const String sweetSpotUnknown = '상태 확인 중';

  /// Sweet Spot 프롬프트
  static String buildSweetSpotPrompt({
    required int babyAgeMonths,
    required bool isPreterm,
    required String stateDescription,
    required int minutesUntilSweetSpot,
  }) {
    return '''
아기 정보:
- 나이: $babyAgeMonths개월${isPreterm ? ' (교정연령)' : ''}
- 현재 상태: $stateDescription
- Sweet Spot까지: $minutesUntilSweetSpot분

부모에게 현재 상황을 간단히 설명하고, 어떻게 해야 하는지 조언해주세요.
2-3문장으로 짧게 답변해주세요.
''';
  }

  /// 아기 정보 질문 프롬프트
  static String buildBabyQuestionPrompt({
    required String babyContext,
    required String question,
  }) {
    return '아기 정보:\n$babyContext\n\n질문: $question';
  }

  /// 다태아 타입 라벨
  static String getMultipleBirthLabel(int babyCount) {
    return switch (babyCount) {
      2 => '쌍둥이',
      3 => '세쌍둥이',
      4 => '네쌍둥이',
      _ => '다태아',
    };
  }

  /// 상황 라벨
  static String getSituationLabel(String situation) {
    return switch (situation) {
      'feeding' => '수유',
      'sleep' => '수면/재우기',
      'diaper' => '기저귀 교체',
      _ => '전반적인 육아',
    };
  }

  /// 다태아 팁 프롬프트
  static String buildMultipleBirthsTipPrompt({
    required String babyType,
    required String situationText,
    List<String>? babyNames,
  }) {
    return '''
$babyType 가정의 $situationText에 대한 실용적인 팁을 알려주세요.
${babyNames != null ? '아기 이름: ${babyNames.join(", ")}' : ''}

- 구체적이고 바로 실행 가능한 팁 2-3개
- 동시에 처리하는 방법 위주
- 부모의 체력 관리도 고려
''';
  }

  /// 에러 메시지 (AI 서비스 내부용, UI 노출 X)
  static const String errorAiDisabled = 'AI features disabled';
  static const String errorAdviceFailed = 'Failed to get AI advice';
  static const String errorSweetSpotFailed = 'Failed to interpret sweet spot';
  static const String errorMultiplesTipFailed = 'Failed to get multiples tip';
}
