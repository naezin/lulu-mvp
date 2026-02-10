import '../../l10n/generated/app_localizations.dart' show S;

/// 아기 출생 유형
enum BabyType {
  singleton('singleton'),
  twin('twin'),
  triplet('triplet'),
  quadruplet('quadruplet');

  const BabyType(this.value);

  final String value;

  /// 표시용 라벨 (i18n)
  String localizedLabel(S l10n) => switch (this) {
        BabyType.singleton => l10n.babyTypeSingleton,
        BabyType.twin => l10n.babyTypeTwin,
        BabyType.triplet => l10n.babyTypeTriplet,
        BabyType.quadruplet => l10n.babyTypeQuadruplet,
      };

  static BabyType fromValue(String value) {
    return BabyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BabyType.singleton,
    );
  }

  static BabyType fromBabyCount(int count) {
    return switch (count) {
      1 => BabyType.singleton,
      2 => BabyType.twin,
      3 => BabyType.triplet,
      _ => BabyType.quadruplet,
    };
  }

  int get maxBabies => switch (this) {
        BabyType.singleton => 1,
        BabyType.twin => 2,
        BabyType.triplet => 3,
        BabyType.quadruplet => 4,
      };
}

/// 동일란/이란 구분
enum Zygosity {
  identical('identical'),
  fraternal('fraternal'),
  unknown('unknown');

  const Zygosity(this.value);

  final String value;

  /// 표시용 라벨 (i18n)
  String localizedLabel(S l10n) => switch (this) {
        Zygosity.identical => l10n.zygosityIdentical,
        Zygosity.fraternal => l10n.zygosityFraternal,
        Zygosity.unknown => l10n.zygosityUnknown,
      };

  static Zygosity fromValue(String value) {
    return Zygosity.values.firstWhere(
      (z) => z.value == value,
      orElse: () => Zygosity.unknown,
    );
  }
}

/// 성장 차트 유형
enum GrowthChartType {
  fenton('fenton', 'Fenton'),
  who('who', 'WHO');

  const GrowthChartType(this.value, this.label);

  final String value;
  final String label;
}

/// 성별
enum Gender {
  male('male'),
  female('female'),
  unknown('unknown');

  const Gender(this.value);

  final String value;

  /// 표시용 라벨 (i18n)
  String localizedLabel(S l10n) => switch (this) {
        Gender.male => l10n.genderMale,
        Gender.female => l10n.genderFemale,
        Gender.unknown => l10n.genderUnknown,
      };

  static Gender fromValue(String value) {
    return Gender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => Gender.unknown,
    );
  }
}

/// 활동 유형
enum ActivityType {
  sleep('sleep'),
  feeding('feeding'),
  diaper('diaper'),
  play('play'),
  health('health');

  const ActivityType(this.value);

  final String value;

  /// 표시용 라벨 (i18n)
  String localizedLabel(S l10n) => switch (this) {
        ActivityType.sleep => l10n.activityTypeSleep,
        ActivityType.feeding => l10n.activityTypeFeeding,
        ActivityType.diaper => l10n.activityTypeDiaper,
        ActivityType.play => l10n.activityTypePlay,
        ActivityType.health => l10n.activityTypeHealth,
      };

  static ActivityType fromValue(String value) {
    return ActivityType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => ActivityType.sleep,
    );
  }
}
