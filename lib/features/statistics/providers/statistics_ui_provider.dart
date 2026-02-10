import 'package:flutter/foundation.dart';

import '../models/weekly_statistics.dart';

/// 통계 UI 상태 Provider
///
/// 작업 지시서 v1.2.1: 펼침/접힘 UI 상태 관리
/// Provider 분리: 펼침/접힘 시 → 카드만 리빌드
class StatisticsUIProvider extends ChangeNotifier {
  /// 현재 펼쳐진 카드 인덱스 (-1: 모두 접힘)
  int _expandedCardIndex = 0; // 기본: 수면 카드 펼침

  /// 로딩 상태
  bool _isLoading = false;

  /// 에러 메시지
  String? _errorMessage;

  // Getters
  int get expandedCardIndex => _expandedCardIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// 특정 카드가 펼쳐져 있는지 확인
  bool isCardExpanded(int index) => _expandedCardIndex == index;

  /// 리포트 타입으로 카드가 펼쳐져 있는지 확인
  bool isReportExpanded(ReportType type) {
    return _expandedCardIndex == type.index;
  }

  /// 카드 토글
  void toggleCard(int index) {
    _expandedCardIndex = _expandedCardIndex == index ? -1 : index;
    notifyListeners();
  }

  /// 리포트 타입으로 카드 토글
  void toggleReport(ReportType type) {
    toggleCard(type.index);
  }

  /// 특정 카드 펼치기
  void expandCard(int index) {
    if (_expandedCardIndex != index) {
      _expandedCardIndex = index;
      notifyListeners();
    }
  }

  /// 모든 카드 접기
  void collapseAll() {
    if (_expandedCardIndex != -1) {
      _expandedCardIndex = -1;
      notifyListeners();
    }
  }

  /// 로딩 상태 설정
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 설정
  void setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  /// 에러 클리어
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// UI 상태 초기화
  void reset() {
    _expandedCardIndex = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
