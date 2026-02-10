import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';

/// 텍스트가 있는 구분선
/// "또는" 등의 텍스트를 가운데 두고 양쪽으로 선이 그어짐
class DividerWithText extends StatelessWidget {
  final String text;
  final Color? color;
  final double thickness;
  final double spacing;

  const DividerWithText({
    super.key,
    required this.text,
    this.color,
    this.thickness = 1,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? LuluColors.greyBorder;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: thickness,
            color: dividerColor,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: thickness,
            color: dividerColor,
          ),
        ),
      ],
    );
  }
}
