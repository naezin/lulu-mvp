import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 딥링크 서비스
///
/// 앱 링크(Universal Links, App Links)를 처리합니다.
/// 초대 코드 딥링크: lulu://invite/{code} 또는 https://lulu.app/invite/{code}
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // 딥링크 이벤트 스트림
  final _linkController = StreamController<DeepLinkEvent>.broadcast();
  Stream<DeepLinkEvent> get linkStream => _linkController.stream;

  // Pending 초대 코드 (로그인 전 저장용)
  static const _pendingCodeKey = 'pending_invite_code';
  String? _pendingInviteCode;
  String? get pendingInviteCode => _pendingInviteCode;

  /// 서비스 초기화
  Future<void> initialize() async {
    // 저장된 pending 코드 복구
    final prefs = await SharedPreferences.getInstance();
    _pendingInviteCode = prefs.getString(_pendingCodeKey);

    // 앱 시작 시 초기 링크 확인
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[WARN] [DeepLinkService] Initial link error: $e');
    }

    // 앱 실행 중 링크 리스닝
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) {
        debugPrint('[ERR] [DeepLinkService] Link stream error: $e');
      },
    );

    debugPrint('[OK] [DeepLinkService] Initialized');
  }

  /// URI 처리
  void _handleUri(Uri uri) {
    debugPrint('[INFO] [DeepLinkService] Received URI: $uri');

    // 초대 링크 확인
    // 지원 형식:
    // - lulu://invite/{code}
    // - https://lulu.app/invite/{code}
    // - https://lulu-baby.web.app/invite/{code}
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'invite') {
      final code = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

      if (code != null && code.isNotEmpty) {
        debugPrint('[INFO] [DeepLinkService] Invite code detected: $code');
        _linkController.add(DeepLinkEvent.invite(code));
      }
    }
  }

  /// Pending 초대 코드 저장 (로그인 전)
  Future<void> savePendingInviteCode(String code) async {
    _pendingInviteCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingCodeKey, code);
    debugPrint('[INFO] [DeepLinkService] Saved pending invite code: $code');
  }

  /// Pending 초대 코드 삭제
  Future<void> clearPendingInviteCode() async {
    _pendingInviteCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCodeKey);
    debugPrint('[INFO] [DeepLinkService] Cleared pending invite code');
  }

  /// 초대 링크 생성
  String createInviteLink(String code) {
    // 프로덕션에서는 실제 도메인 사용
    return 'https://lulu.app/invite/$code';
  }

  /// 서비스 해제
  void dispose() {
    _linkSubscription?.cancel();
    _linkController.close();
  }
}

/// 딥링크 이벤트
class DeepLinkEvent {
  final DeepLinkType type;
  final String? inviteCode;
  final Map<String, dynamic>? data;

  const DeepLinkEvent._({
    required this.type,
    this.inviteCode,
    this.data,
  });

  /// 초대 이벤트
  factory DeepLinkEvent.invite(String code) {
    return DeepLinkEvent._(
      type: DeepLinkType.invite,
      inviteCode: code,
    );
  }

  /// 알 수 없는 이벤트
  factory DeepLinkEvent.unknown(Map<String, dynamic> data) {
    return DeepLinkEvent._(
      type: DeepLinkType.unknown,
      data: data,
    );
  }

  @override
  String toString() {
    return 'DeepLinkEvent(type: $type, code: $inviteCode)';
  }
}

/// 딥링크 타입
enum DeepLinkType {
  invite,
  unknown,
}
