import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 관리 Provider
///
/// - 언어 설정 (locale)
/// - 톤 설정 (warm/plain)
/// - SharedPreferences로 영속성 보장
/// - 최초 실행 시 시스템 언어 감지 후 지원 언어면 적용
class SettingsProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _warmToneKey = 'app_warm_tone';
  static const List<String> _supportedCodes = ['ko', 'en'];

  Locale _locale = const Locale('ko');
  bool _isWarmTone = true;
  bool _isInitialized = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isWarmTone => _isWarmTone;
  bool get isInitialized => _isInitialized;

  /// 초기화 (앱 시작 시 await로 호출)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null && _supportedCodes.contains(savedLocale)) {
      // 저장된 설정이 있고 지원 언어면 사용
      _locale = Locale(savedLocale);
    } else {
      // 최초 실행: 시스템 언어 감지
      final systemLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (_supportedCodes.contains(systemLang)) {
        _locale = Locale(systemLang);
      } else {
        _locale = const Locale('en'); // 폴백
      }
    }

    // 톤 설정 로드 (기본값: warm)
    final savedTone = prefs.getBool(_warmToneKey);
    if (savedTone != null) {
      _isWarmTone = savedTone;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 언어 변경
  Future<void> setLocale(String code) async {
    if (!_supportedCodes.contains(code)) return;
    if (_locale.languageCode == code) return;

    _locale = Locale(code);

    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);

    notifyListeners();
  }

  /// 톤 변경 (warm ↔ plain)
  Future<void> setWarmTone(bool warm) async {
    if (_isWarmTone == warm) return;

    _isWarmTone = warm;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_warmToneKey, warm);

    notifyListeners();
  }

  /// 지원 언어 목록 (시스템 설정 제거됨)
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'ko', label: '한국어'), // l10n: native label
    LanguageOption(code: 'en', label: 'English'),
  ];
}

/// 언어 옵션 모델 (간소화)
class LanguageOption {
  final String code;
  final String label; // 네이티브 이름만

  const LanguageOption({
    required this.code,
    required this.label,
  });
}
