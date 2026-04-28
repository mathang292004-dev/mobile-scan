import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

/// Guide dialog shown when the eye icon in the Approval Panel AppBar is tapped.
/// Figma node 71:100369.
class ApproverGuideDialog extends StatelessWidget {
  static OverlayEntry? _entry;
  final VoidCallback? onClose;
  const ApproverGuideDialog({super.key, this.onClose});

  static void show(BuildContext context, GlobalKey key) {
    if (_entry?.mounted ?? false) {
      _entry?.remove();
      _entry = null;
      return;
    }

    final overlay = Overlay.of(context);

    final ctx = key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    final double iconCenterY = position.dy + size.height / 2;
    final double dialogTop = position.dy + size.height + 8;
    final double rightEdge =
        MediaQuery.of(context).size.width - position.dx - size.width;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _entry?.remove();
                  _entry = null;
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              top: iconCenterY - 18,
              right: rightEdge + size.width + 8,
              child: const _GuideTooltipBubble(),
            ),

            Positioned(
              top: dialogTop,
              right: rightEdge,
              child: Material(
                color: Colors.transparent,
                child: ApproverGuideDialog(
                  onClose: () {
                    _entry?.remove();
                    _entry = null;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
  }

  static const _steps = [
    (title: TextHelper.guideStep1Title, sub: TextHelper.guideStep1Sub),
    (title: TextHelper.guideStep2Title, sub: TextHelper.guideStep2Sub),
    (title: TextHelper.guideStep3Title, sub: TextHelper.guideStep3Sub),
    (title: TextHelper.guideStep4Title, sub: TextHelper.guideStep4Sub),
    (title: TextHelper.guideStep5Title, sub: TextHelper.guideStep5Sub),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TextHelper.guide,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D0D0D),
                ),
              ),
              // GestureDetector(
              //   onTap: onClose,
              //   child: Container(
              //     width: 28,
              //     height: 28,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       border: Border.all(
              //         color: ColorHelper.black4.withValues(alpha: 0.3),
              //       ),
              //     ),
              //     child: const Icon(
              //       Icons.close,
              //       size: 14,
              //       color: ColorHelper.black4,
              //     ),
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 16),

          ..._steps.asMap().entries.map(
                (e) => _StepRow(
              stepNumber: e.key + 1,
              title: e.value.title,
              subtitle: e.value.sub,
              isActive: e.key == 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final bool isActive;

  const _StepRow({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorHelper.primaryColor
                  : ColorHelper.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: isActive
                    ? ColorHelper.white
                    : ColorHelper.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF0D0D0D)
                        : const Color(0xFF0D0D0D).withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF525252).withValues(
                      alpha: isActive ? 1.0 : 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuideTooltipBubble extends StatefulWidget {
  const _GuideTooltipBubble();

  @override
  State<_GuideTooltipBubble> createState() => _GuideTooltipBubbleState();
}

class _GuideTooltipBubbleState extends State<_GuideTooltipBubble> {
  bool visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              TextHelper.useThisGuide,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 🔹 Small arrow pointing to icon (right side)
          CustomPaint(
            size: const Size(6, 10),
            painter: _TooltipArrowPainter(),
          ),
        ],
      ),
    );
  }
}