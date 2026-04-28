import 'package:flutter/material.dart';
import '../../../../generated/color_helper.dart';
import '../model/org_role_model.dart';

/// A widget representing a single node in the organization chart
/// Shows role title with gradient background and avatar (Figma design)
class OrgNodeWidget extends StatelessWidget {
  /// The role data to display
  final OrgRole role;

  /// Callback when the node is tapped
  final VoidCallback? onTap;

  /// Whether this node is selected
  final bool isSelected;

  const OrgNodeWidget({
    super.key,
    required this.role,
    this.onTap,
    this.isSelected = false,
  });

  Color _getNodeColor() {
    final colorCode = role.colorCode.replaceAll('#', '');
    return Color(int.parse('FF$colorCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final nodeColor = _getNodeColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border(
            top: BorderSide(color: nodeColor, width: 3),
            left: BorderSide(color: nodeColor, width: 1),
            right: BorderSide(color: nodeColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Role title - centered
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),

                child: Text(
                  role.title.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nodeColor,
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Person icon at top center, slightly protruding from border
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ColorHelper.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(top: BorderSide(color: nodeColor, width: 3)),
                  ),
                  child: Icon(Icons.person, size: 16, color: nodeColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
