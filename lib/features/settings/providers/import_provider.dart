import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/import_service.dart';
import '../../../core/services/family_sync_service.dart';
import '../../../core/services/parsers/parsed_activity.dart';

/// Import 상태
enum ImportState {
  /// 초기 상태 (파일 선택 대기)
  initial,

  /// 파일 분석 중
  analyzing,

  /// 미리보기 (파일 분석 완료)
  preview,

  /// 가져오기 중
  importing,

  /// 완료
  complete,

  /// 오류
  error,
}

/// Import Provider
///
/// 데이터 가져오기 화면의 상태 관리
class ImportProvider extends ChangeNotifier {
  final ImportService _importService = ImportService();

  // 현재 상태
  ImportState _state = ImportState.initial;
  ImportState get state => _state;

  // 선택된 파일
  File? _selectedFile;
  File? get selectedFile => _selectedFile;

  // 분석 결과
  ImportPreview? _preview;
  ImportPreview? get preview => _preview;

  // Import 결과
  ImportResult? _result;
  ImportResult? get result => _result;

  // 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 진행률 (0.0 ~ 1.0)
  double _progress = 0.0;
  double get progress => _progress;

  /// 상태 초기화
  void reset() {
    _state = ImportState.initial;
    _selectedFile = null;
    _preview = null;
    _result = null;
    _errorMessage = null;
    _progress = 0.0;
    notifyListeners();
  }

  /// TXT 파일 선택
  Future<bool> pickTxtFile() async {
    return _pickFile(['txt']);
  }

  /// CSV 파일 선택
  Future<bool> pickCsvFile() async {
    return _pickFile(['csv']);
  }

  /// 파일 선택 (내부)
  Future<bool> _pickFile(List<String> extensions) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );

      if (result != null && result.files.single.path != null) {
        _selectedFile = File(result.files.single.path!);
        await _analyzeFile();
        return true;
      }

      return false;
    } catch (e) {
      _setError('Failed to select file: $e');
      return false;
    }
  }

  /// 파일 분석
  Future<void> _analyzeFile() async {
    if (_selectedFile == null) return;

    _state = ImportState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      _preview = await _importService.analyzeFile(_selectedFile!);
      _state = ImportState.preview;
    } catch (e) {
      _setError(e.toString());
    }

    notifyListeners();
  }

  /// 가져오기 실행
  Future<bool> startImport({
    required String babyId,
    required String familyId,
  }) async {
    if (_preview == null) return false;

    _state = ImportState.importing;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // IMPORTANT: Ensure Family exists in Supabase before import!
      debugPrint('[INFO] [ImportProvider] Ensuring family exists before import...');
      debugPrint('[INFO] [ImportProvider] Original familyId from screen: $familyId');

      final syncedFamilyId = await FamilySyncService.instance.ensureFamilyExists();
      debugPrint('[INFO] [ImportProvider] Synced familyId from FamilySyncService: $syncedFamilyId');

      // 동기화된 familyId 사용 (없으면 전달받은 familyId 사용)
      final actualFamilyId = syncedFamilyId ?? familyId;
      debugPrint('[INFO] [ImportProvider] Final familyId to use: $actualFamilyId');

      if (actualFamilyId.isEmpty) {
        _setError('No family info found. Please complete onboarding.');
        return false;
      }

      _result = await _importService.importActivities(
        preview: _preview!,
        babyId: babyId,
        familyId: actualFamilyId,
        onProgress: (progress) {
          _progress = progress;
          notifyListeners();
        },
      );

      _state = ImportState.complete;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Import failed: $e');
      return false;
    }
  }

  /// 에러 설정
  void _setError(String message) {
    _state = ImportState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// 파일 유형 이름
  String get fileTypeName {
    if (_selectedFile == null) return '';
    return _importService.getFileTypeName(_selectedFile!.path);
  }

  /// 파일 이름
  String get fileName {
    if (_selectedFile == null) return '';
    return _selectedFile!.path.split('/').last;
  }
}
