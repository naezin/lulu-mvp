import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/activity_repository.dart';

/// Record Base Provider (abstract)
///
/// Sprint 21 Phase 2-2: RecordProvider 5-way split
/// Shared state and methods for all record providers:
/// - familyId, babies, selectedBabyIds
/// - recordTime, notes
/// - isLoading, errorMessage
/// - initialize, setSelectedBabyIds, setRecordTime, setNotes
abstract class RecordBaseProvider extends ChangeNotifier {
  @protected
  final ActivityRepository activityRepository = ActivityRepository();

  @protected
  final Uuid uuid = const Uuid();

  // ========================================
  // Shared state
  // ========================================

  /// Family ID
  String? _familyId;
  String? get familyId => _familyId;

  /// Available babies
  List<BabyModel> _babies = [];
  List<BabyModel> get babies => List.unmodifiable(_babies);

  /// Selected baby IDs (MVP-F: single selection only)
  List<String> _selectedBabyIds = [];
  List<String> get selectedBabyIds => List.unmodifiable(_selectedBabyIds);

  /// Selected single baby ID
  String? get selectedBabyId =>
      _selectedBabyIds.isNotEmpty ? _selectedBabyIds.first : null;

  /// Record time
  DateTime _recordTime = DateTime.now();
  DateTime get recordTime => _recordTime;

  /// Notes
  String? _notes;
  String? get notes => _notes;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Selection validity check
  bool get isSelectionValid => _selectedBabyIds.isNotEmpty;

  // ========================================
  // Common methods
  // ========================================

  /// Provider initialization
  void initialize({
    required String familyId,
    required List<BabyModel> babies,
    String? preselectedBabyId,
  }) {
    _familyId = familyId;
    _babies = babies;
    _recordTime = DateTime.now();
    _notes = null;
    _errorMessage = null;

    // Default selection: passed ID or first baby
    if (preselectedBabyId != null) {
      _selectedBabyIds = [preselectedBabyId];
    } else if (babies.isNotEmpty) {
      _selectedBabyIds = [babies.first.id];
    } else {
      _selectedBabyIds = [];
    }

    // Subclass-specific initialization
    initializeActivityState();

    notifyListeners();
  }

  /// Subclass hook: reset activity-specific state
  @protected
  void initializeActivityState();

  /// Baby selection change (MB-02: with data caching)
  void setSelectedBabyIds(List<String> babyIds) {
    // List equality check
    if (_selectedBabyIds.length == babyIds.length &&
        _selectedBabyIds.every((id) => babyIds.contains(id))) {
      return;
    }

    // Save current baby data
    final previousBabyId = selectedBabyId;
    if (previousBabyId != null) {
      saveCacheForBaby(previousBabyId);
    }

    _selectedBabyIds = List.from(babyIds);

    // Restore new baby data
    final newBabyId = selectedBabyId;
    if (newBabyId != null) {
      restoreCacheForBaby(newBabyId);
    }

    notifyListeners();
  }

  /// MB-02: Save current data to cache (subclass implements)
  @protected
  void saveCacheForBaby(String babyId);

  /// MB-02: Restore data from cache (subclass implements)
  @protected
  void restoreCacheForBaby(String babyId);

  /// Record time change
  void setRecordTime(DateTime time) {
    if (_recordTime == time) return;
    _recordTime = time;
    notifyListeners();
  }

  /// Notes change
  void setNotes(String? notes) {
    _notes = notes?.trim().isEmpty == true ? null : notes?.trim();
  }

  /// Reset shared state
  @protected
  void resetBase() {
    _familyId = null;
    _babies = [];
    _selectedBabyIds = [];
    _recordTime = DateTime.now();
    _notes = null;
    _isLoading = false;
    _errorMessage = null;
  }

  /// Full reset (shared + activity-specific)
  void reset() {
    resetBase();
    resetActivityState();
    notifyListeners();
  }

  /// Subclass hook: reset activity-specific state
  @protected
  void resetActivityState();

  // ========================================
  // Protected helpers for subclasses
  // ========================================

  /// Set loading state
  @protected
  void setLoading(bool loading) {
    _isLoading = loading;
  }

  /// Set error message
  @protected
  void setError(String? message) {
    _errorMessage = message;
  }

  /// Validate before save (common pattern)
  @protected
  bool validateBeforeSave() {
    if (!isSelectionValid) {
      _errorMessage = 'errorSelectBaby';
      notifyListeners();
      return false;
    }

    if (_familyId == null) {
      _errorMessage = 'errorNoFamily';
      notifyListeners();
      return false;
    }

    return true;
  }
}
