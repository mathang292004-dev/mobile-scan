import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/presentation/organization_structure/cubit/org_structure_cubit.dart';
import 'package:emergex/presentation/organization_structure/model/org_role_model.dart';
import 'package:emergex/presentation/organization_structure/widgets/org_node_widget.dart';
import 'package:emergex/presentation/organization_structure/widgets/role_members_modal_widget.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrganizationStructureScreen extends StatelessWidget {
  const OrganizationStructureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.orgStructureCubit..loadOrgStructure(),
      child: BlocBuilder<OrgStructureCubit, OrgStructureState>(
        builder: (context, state) {
          if (state.isLoading) {
            return AppScaffold(
              appBar: const AppBarWidget(showBackButton: false),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state.processState == ProcessState.error &&
              state.rootRole == null) {
            return AppScaffold(
              appBar: const AppBarWidget(showBackButton: false),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Error: ${state.errorMessage ?? "Failed to load organization structure"}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.red[700],
                              height: 1.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          AppDI.orgStructureCubit.loadOrgStructure(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return AppScaffold(
            appBar: const AppBarWidget(showBackButton: false),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF2E8), Color(0xFFB9C7B5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.6095],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Organization Structure',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C2C2E),
                                    height: 1.67,
                                    letterSpacing: -0.2,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(24),
                            border:
                                Border.all(color: Colors.white, width: 1),
                          ),
                          child: state.rootRole != null
                              ? LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: Center(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 40,
                                                horizontal: 20,
                                              ),
                                              child: _buildOrgChart(
                                                context,
                                                state.rootRole!,
                                                state.selectedRoleId,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const Center(child: SizedBox()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleNodeTap(BuildContext context, OrgRole role) {
    AppDI.orgStructureCubit.selectRole(role.id);
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => RoleMembersModal(role: role),
    );
  }

  Widget _buildOrgChart(
    BuildContext context,
    OrgRole rootRole,
    String? selectedRoleId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNode(context, rootRole, selectedRoleId),
        if (rootRole.hasChildren) ...[
          CustomPaint(
            size: const Size(2, 35),
            painter: _VerticalLinePainter(_getNodeColor(rootRole)),
          ),
          _buildChildrenRow(context, rootRole.children, selectedRoleId),
        ],
      ],
    );
  }

  Widget _buildNode(
    BuildContext context,
    OrgRole role,
    String? selectedRoleId,
  ) {
    return OrgNodeWidget(
      role: role,
      onTap: () => _handleNodeTap(context, role),
      isSelected: selectedRoleId == role.id,
    );
  }

  Widget _buildChildrenRow(
    BuildContext context,
    List<OrgRole> children,
    String? selectedRoleId,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();

    final lineColor = _getNodeColor(children.first);

    if (children.length == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(2, 35),
            painter: _ArrowConnectorPainter(lineColor),
          ),
          _buildNode(context, children[0], selectedRoleId),
          if (children[0].hasChildren) ...[
            CustomPaint(
              size: const Size(2, 30),
              painter: _VerticalLinePainter(lineColor),
            ),
            _buildGrandchildrenRow(
                context, children[0].children, children[0], selectedRoleId),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(_calculateRowWidth(children.length * 2), 30),
          painter: _TJunctionPainter(lineColor),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildNodeListWithSpacing(
            context,
            children,
            selectedRoleId,
            isGrandchildren: false,
          ),
        ),
      ],
    );
  }

  Widget _buildGrandchildrenRow(
    BuildContext context,
    List<OrgRole> children,
    OrgRole parent,
    String? selectedRoleId,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();

    final parentColor = _getNodeColor(parent);

    if (children.length == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(2, 35),
            painter: _ArrowConnectorPainter(parentColor),
          ),
          _buildNode(context, children[0], selectedRoleId),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(_calculateRowWidth(children.length) * 0.9, 35),
          painter: _TJunctionPainter(parentColor),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildNodeListWithSpacing(
            context,
            children,
            selectedRoleId,
            isGrandchildren: true,
            parentColor: parentColor,
          ),
        ),
      ],
    );
  }

  Color _getNodeColor(OrgRole role) {
    final colorCode = role.colorCode.replaceAll('#', '');
    return Color(int.parse('FF$colorCode', radix: 16));
  }

  List<Widget> _buildNodeListWithSpacing(
    BuildContext context,
    List<OrgRole> children,
    String? selectedRoleId, {
    bool isGrandchildren = false,
    Color? parentColor,
  }) {
    final List<Widget> widgets = [];
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final childColor = isGrandchildren
          ? (parentColor ?? Colors.grey[400]!)
          : _getNodeColor(child);

      widgets.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(20, 35),
              painter: _CurvedArrowConnectorPainter(childColor),
            ),
            _buildNode(context, child, selectedRoleId),
            if (!isGrandchildren && child.hasChildren) ...[
              CustomPaint(
                size: const Size(2, 30),
                painter: _VerticalLinePainter(childColor),
              ),
              _buildGrandchildrenRow(
                  context, child.children, child, selectedRoleId),
            ],
          ],
        ),
      );

      if (i < children.length - 1) {
        widgets.add(const SizedBox(width: 40));
      }
    }
    return widgets;
  }

  double _calculateRowWidth(int childCount) {
    return (childCount * 140.0) + ((childCount - 1) * 40.0);
  }
}

/// Custom painter for vertical lines (without arrow)
class _VerticalLinePainter extends CustomPainter {
  final Color color;

  _VerticalLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for vertical connector lines with downward arrow
class _ArrowConnectorPainter extends CustomPainter {
  final Color color;

  _ArrowConnectorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    const lineStartY = 0.0;
    final lineEndY = size.height - 8.0;

    canvas.drawLine(
      Offset(centerX, lineStartY),
      Offset(centerX, lineEndY),
      paint,
    );

    const arrowSize = 5.0;
    final path = Path()
      ..moveTo(centerX - arrowSize, lineEndY - arrowSize)
      ..lineTo(centerX, lineEndY)
      ..lineTo(centerX + arrowSize, lineEndY - arrowSize);

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for T-junction connector (vertical line connecting to horizontal line with curves)
class _TJunctionPainter extends CustomPainter {
  final Color color;

  _TJunctionPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final horizontalY = size.height - 10;
    const curveRadius = 12.0;

    final path = Path();

    path.moveTo(centerX, 0);
    path.lineTo(centerX, horizontalY - curveRadius);

    path.quadraticBezierTo(
      centerX,
      horizontalY,
      centerX - curveRadius,
      horizontalY,
    );

    path.lineTo(0, horizontalY);

    path.moveTo(centerX, horizontalY - curveRadius);

    path.quadraticBezierTo(
      centerX,
      horizontalY,
      centerX + curveRadius,
      horizontalY,
    );

    path.lineTo(size.width, horizontalY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for curved connector from horizontal line to node with arrow
class _CurvedArrowConnectorPainter extends CustomPainter {
  final Color color;

  _CurvedArrowConnectorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final lineEndY = size.height - 8.0;

    final path = Path();
    path.moveTo(centerX, 0);
    path.lineTo(centerX, lineEndY);

    canvas.drawPath(path, paint);

    const arrowSize = 5.0;
    final arrowPath = Path()
      ..moveTo(centerX - arrowSize, lineEndY - arrowSize)
      ..lineTo(centerX, lineEndY)
      ..lineTo(centerX + arrowSize, lineEndY - arrowSize);

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
