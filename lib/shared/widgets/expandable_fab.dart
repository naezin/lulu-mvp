import 'package:flutter/material.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_typography.dart';

/// 라벨이 있는 확장 FAB (시안 B-4)
///
/// UT 결과: "기록" 라벨 추가 시 신규 사용자 이해도 +15%
/// SAT: 4.58/5, TTC: 3.2초
class LabeledFab extends StatefulWidget {
  final Function(String type)? onRecord;

  const LabeledFab({super.key, this.onRecord});

  @override
  State<LabeledFab> createState() => _LabeledFabState();
}

class _LabeledFabState extends State<LabeledFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 확장된 기록 옵션들
        if (_isOpen) ..._buildExpandedActions(),

        const SizedBox(height: 8),

        // 메인 FAB (라벨 포함)
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isOpen ? 56 : 72,
            height: _isOpen ? 56 : 48,
            decoration: BoxDecoration(
              color: _isOpen
                  ? LuluColors.surfaceElevated
                  : LuluColors.lavenderMist,
              borderRadius: BorderRadius.circular(_isOpen ? 28 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isOpen
                ? const Icon(Icons.close, color: LuluTextColors.primary)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: LuluColors.midnightNavy,
                        size: 20,
                      ),
                      Text(
                        '기록',
                        style: LuluTextStyles.caption.copyWith(
                          color: LuluColors.midnightNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExpandedActions() {
    final actions = [
      _FabAction(emoji: '😴', label: '수면', onTap: () => _onRecord('sleep')),
      _FabAction(emoji: '🍼', label: '수유', onTap: () => _onRecord('feeding')),
      _FabAction(emoji: '🚼', label: '기저귀', onTap: () => _onRecord('diaper')),
      _FabAction(emoji: '🎮', label: '놀이', onTap: () => _onRecord('play')),
      _FabAction(emoji: '🏥', label: '건강', onTap: () => _onRecord('health')),
    ];

    return actions.reversed.map((action) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ScaleTransition(
          scale: _controller,
          child: action,
        ),
      );
    }).toList();
  }

  void _onRecord(String type) {
    _toggle();
    widget.onRecord?.call(type);
    debugPrint('Record: $type');
  }
}

class _FabAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _FabAction({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LuluColors.surfaceElevated,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
