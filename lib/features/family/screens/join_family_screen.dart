import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/providers/home_provider.dart';
import '../models/invite_info_model.dart';
import '../providers/family_provider.dart';
import '../services/invite_service.dart';
import 'baby_mapping_screen.dart';

/// 가족 참여 화면
///
/// 초대 코드를 입력하여 다른 가족에 참여합니다.
class JoinFamilyScreen extends StatefulWidget {
  final String? initialCode;

  const JoinFamilyScreen({super.key, this.initialCode});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  final _inviteService = InviteService();

  bool _isLoading = false;
  InviteInfoModel? _inviteInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      _verifyCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        title: Text(l10n.joinFamily),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Text(
                l10n.enterInviteCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: LuluTextColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterInviteCodeDesc,
                style: TextStyle(
                  fontSize: 14,
                  color: LuluTextColors.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // 코드 입력
              _buildCodeInput(l10n),

              // 에러 메시지
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red[300], fontSize: 14),
                ),
              ],

              // 초대 정보 미리보기
              if (_inviteInfo != null && _inviteInfo!.isValid) ...[
                const SizedBox(height: 24),
                _buildInvitePreview(l10n),
              ],

              const Spacer(),

              // 참여 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canJoin ? _joinFamily : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuluColors.lavenderMist,
                    disabledBackgroundColor: LuluColors.deepIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LuluRadius.sm),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LuluColors.midnightNavy,
                          ),
                        )
                      : Text(
                          l10n.joinFamilyButton,
                          style: const TextStyle(
                            color: LuluColors.midnightNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput(S l10n) {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.deepIndigo.withOpacity(0.5),
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: TextField(
        controller: _codeController,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: LuluTextColors.primary,
          letterSpacing: 4,
        ),
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
          LengthLimitingTextInputFormatter(7), // ABC-123
        ],
        decoration: InputDecoration(
          hintText: 'ABC-123',
          hintStyle: TextStyle(
            color: LuluTextColors.primary.withOpacity(0.3),
            letterSpacing: 4,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: IconButton(
            onPressed: _isLoading ? null : _verifyCode,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LuluColors.lavenderMist,
                    ),
                  )
                : const Icon(LuluIcons.search, color: LuluColors.lavenderMist),
          ),
        ),
        onChanged: (value) {
          // 자동 하이픈 삽입
          if (value.length == 3 && !value.contains('-')) {
            _codeController.text = '$value-';
            _codeController.selection = TextSelection.fromPosition(
              TextPosition(offset: _codeController.text.length),
            );
          }

          // 상태 초기화
          if (_inviteInfo != null || _error != null) {
            setState(() {
              _inviteInfo = null;
              _error = null;
            });
          }
        },
        onSubmitted: (_) => _verifyCode(),
      ),
    );
  }

  Widget _buildInvitePreview(S l10n) {
    final info = _inviteInfo!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.lavenderMist.withOpacity(0.1),
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(color: LuluColors.lavenderMist.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LuluIcons.checkCircle,
                  color: LuluColors.lavenderMist, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.validInvite,
                style: const TextStyle(
                  color: LuluColors.lavenderMist,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
              LuluIcons.people, l10n.memberCount(info.memberCount.toString())),
          if (info.babies.isNotEmpty)
            _buildInfoRow(LuluIcons.baby,
                l10n.babyNames(info.babies.map((b) => b.name).join(', '))),
          _buildInfoRow(LuluIcons.timer, l10n.expiresIn(info.daysLeft.toString())),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: LuluTextColors.primary.withOpacity(0.6)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: LuluTextColors.primary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  bool get _canJoin =>
      _inviteInfo != null && _inviteInfo!.isValid && !_isLoading;

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final info = await _inviteService.getInviteInfo(code);
      setState(() {
        _inviteInfo = info;
        if (!info.isValid) {
          _error = info.error;
        }
      });
    } catch (e) {
      setState(() {
        _error = '초대 코드를 확인할 수 없어요';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinFamily() async {
    if (_inviteInfo == null || !_inviteInfo!.isValid) return;

    final code = _codeController.text.trim();
    final myBabies = context.read<HomeProvider>().babies;

    // 내 아기가 있고, 새 가족에도 아기가 있으면 매핑 화면으로
    if (myBabies.isNotEmpty && _inviteInfo!.babies.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BabyMappingScreen(
            inviteCode: code,
            inviteInfo: _inviteInfo!,
          ),
        ),
      );
      return;
    }

    // 바로 참여
    setState(() => _isLoading = true);

    try {
      final result = await _inviteService.acceptInvite(code, null);

      if (mounted) {
        await context.read<FamilyProvider>().onJoinedFamily(result.familyId);
        await context.read<HomeProvider>().onFamilyChanged(result.familyId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context)!.joinedFamily)),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
