import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/providers/home_provider.dart';
import '../models/invite_info_model.dart';
import '../providers/family_provider.dart';
import '../services/invite_service.dart';

/// 아기 매핑 화면
///
/// 가족 참여 시 기존 기록을 새 가족 아기로 매핑합니다.
class BabyMappingScreen extends StatefulWidget {
  final String inviteCode;
  final InviteInfoModel inviteInfo;

  const BabyMappingScreen({
    super.key,
    required this.inviteCode,
    required this.inviteInfo,
  });

  @override
  State<BabyMappingScreen> createState() => _BabyMappingScreenState();
}

class _BabyMappingScreenState extends State<BabyMappingScreen> {
  final _inviteService = InviteService();
  final Map<String, String?> _mappings = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoMatchBabies();
  }

  void _autoMatchBabies() {
    final myBabies = context.read<HomeProvider>().babies;

    // 이름 기준 자동 매칭
    for (final myBaby in myBabies) {
      final match = widget.inviteInfo.babies.firstWhereOrNull(
        (b) => b.name.toLowerCase() == myBaby.name.toLowerCase(),
      );
      if (match != null) {
        _mappings[myBaby.id] = match.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final myBabies = context.read<HomeProvider>().babies;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        title: Text(l10n.importRecords),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              l10n.mapBabiesTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mapBabiesDesc,
              style: TextStyle(
                fontSize: 14,
                color: LuluTextColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // 매핑 목록
            Expanded(
              child: ListView.builder(
                itemCount: myBabies.length,
                itemBuilder: (context, index) {
                  final myBaby = myBabies[index];
                  return _buildMappingRow(myBaby, l10n);
                },
              ),
            ),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _skipMapping,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: LuluColors.lavenderMist),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.skipImport,
                      style: const TextStyle(color: LuluColors.lavenderMist),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _migrateRecords,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuluColors.lavenderMist,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            l10n.importRecordsButton,
                            style: const TextStyle(
                              color: LuluColors.midnightNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingRow(myBaby, S l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.deepIndigo.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 내 아기
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LuluColors.lavenderMist.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.child_care_rounded,
                      size: 18,
                      color: LuluColors.lavenderMist,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  myBaby.name,
                  style: const TextStyle(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 화살표
          Icon(
            Icons.arrow_forward,
            size: 20,
            color: LuluTextColors.primary.withOpacity(0.5),
          ),
          const SizedBox(width: 12),

          // 대상 아기 선택
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: LuluColors.midnightNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: LuluColors.lavenderMist.withOpacity(0.3),
                ),
              ),
              child: DropdownButton<String?>(
                value: _mappings[myBaby.id],
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: LuluColors.deepIndigo,
                hint: Text(
                  l10n.selectBaby,
                  style: TextStyle(
                    color: LuluTextColors.primary.withOpacity(0.5),
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      l10n.doNotLink,
                      style: TextStyle(
                        color: LuluTextColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                  ...widget.inviteInfo.babies.map((baby) => DropdownMenuItem(
                        value: baby.id,
                        child: Text(
                          baby.name,
                          style: const TextStyle(color: LuluTextColors.primary),
                        ),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _mappings[myBaby.id] = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _skipMapping() async {
    setState(() => _isLoading = true);

    try {
      final result =
          await _inviteService.acceptInvite(widget.inviteCode, null);

      if (mounted) {
        await context.read<FamilyProvider>().onJoinedFamily(result.familyId);
        await context.read<HomeProvider>().onFamilyChanged(result.familyId);

        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _migrateRecords() async {
    // 유효한 매핑만 추출
    final mappings = _mappings.entries
        .where((e) => e.value != null)
        .map((e) => BabyMapping(fromBabyId: e.key, toBabyId: e.value!))
        .toList();

    // 매핑이 없으면 skip과 동일
    if (mappings.isEmpty) {
      await _skipMapping();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result =
          await _inviteService.acceptInvite(widget.inviteCode, mappings);

      if (mounted) {
        await context.read<FamilyProvider>().onJoinedFamily(result.familyId);
        await context.read<HomeProvider>().onFamilyChanged(result.familyId);

        final l10n = S.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recordsImported(result.migratedCount))),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
