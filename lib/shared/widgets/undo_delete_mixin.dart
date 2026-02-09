import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../../features/home/providers/home_provider.dart';
import '../../l10n/generated/app_localizations.dart' show S;
import '../../core/design_system/lulu_icons.dart';

/// Undo 삭제 기능을 제공하는 Mixin
///
/// 작업 지시서 v1.1: Hard Delete + Undo 토스트 (5초)
/// - 삭제 전 ActivityModel을 메모리에 보관
/// - 5초 Undo 토스트 표시
/// - Undo 시 새 UUID로 재생성 (duplicate key 방지)
mixin UndoDeleteMixin<T extends StatefulWidget> on State<T> {
  final ActivityRepository _activityRepository = ActivityRepository();
  ActivityModel? _pendingDelete;

  /// 삭제 실행 + Undo 토스트 표시
  Future<void> deleteActivityWithUndo({
    required ActivityModel activity,
    required HomeProvider homeProvider,
    required BuildContext context,
  }) async {
    // 1. Undo용 백업
    _pendingDelete = activity;

    // Sprint 20 HF #1: ScaffoldMessenger를 미리 캡처하여 context 무효화 방지
    final messenger = ScaffoldMessenger.of(context);
    final l10n = S.of(context);

    // 2. 즉시 삭제 (DB + 로컬 상태)
    try {
      await _activityRepository.deleteActivity(activity.id);
      homeProvider.removeActivity(activity.id);
    } catch (e) {
      _pendingDelete = null;
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
      return;
    }

    // 3. Undo 토스트 표시 (5초)
    // Sprint 20 HF #1: 캡처된 messenger 사용 → 탭 전환 후에도 정상 dismiss
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LuluIcons.checkCircleOutline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n?.recordDeleted ?? 'Record deleted'),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n?.undoAction ?? 'Undo',
          textColor: Colors.white,
          onPressed: () => _undoDelete(homeProvider, messenger),
        ),
      ),
    );

    // 4. 5초 후 백업 삭제
    Future.delayed(const Duration(seconds: 6), () {
      _pendingDelete = null;
    });
  }

  /// 삭제 취소 (재생성)
  /// 🔴 중요: 새 ID로 생성해야 DB 충돌 방지
  /// Sprint 20 HF #1: ScaffoldMessengerState 직접 전달 → context 무효화 방지
  Future<void> _undoDelete(HomeProvider homeProvider, ScaffoldMessengerState messenger) async {
    if (_pendingDelete == null) return;

    try {
      // 🔴 중요: 새 UUID 생성하여 ID 충돌 방지
      final restoredActivity = _pendingDelete!.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
      );

      final created = await _activityRepository.createActivity(restoredActivity);
      homeProvider.addActivity(created);

      // 🔧 Sprint 19 G-F1: 복구 성공 토스트 제거 → 햅틱 대체
      HapticFeedback.mediumImpact();
    } catch (e) {
      try {
        messenger.showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      } catch (_) {
        // messenger가 이미 dispose된 경우 무시
      }
    } finally {
      _pendingDelete = null;
    }
  }
}
