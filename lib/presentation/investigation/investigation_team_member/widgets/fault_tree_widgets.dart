import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/fault_tree_cubit.dart';
import '../data/model/fault_tree_model.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

class FaultTreeBuilderWidget extends StatefulWidget {
  const FaultTreeBuilderWidget({super.key});

  @override
  State<FaultTreeBuilderWidget> createState() => _FaultTreeBuilderWidgetState();
}

class _FaultTreeBuilderWidgetState extends State<FaultTreeBuilderWidget> {
  late final FaultTreeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = FaultTreeCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _cubit, child: const _FaultTreeContent());
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN CANVAS
// ═══════════════════════════════════════════════════════════════════

class _FaultTreeContent extends StatefulWidget {
  const _FaultTreeContent();

  @override
  State<_FaultTreeContent> createState() => _FaultTreeContentState();
}

class _FaultTreeContentState extends State<_FaultTreeContent> {
  final TransformationController _transformationController =
      TransformationController();
  BoxConstraints? _lastConstraints;
  bool _panEnabled = true;

  void _setPanEnabled(bool enabled) {
    if (_panEnabled != enabled) {
      setState(() => _panEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3DA229).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Grid & Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              _lastConstraints = constraints;
              return InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.1,
                maxScale: 2.0,
                panEnabled: _panEnabled,
                child: SizedBox(
                  width: 2000,
                  height: 2000,
                  child: Stack(
                    children: [
                      // Grid Background & Selection Clearer
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            context.read<FaultTreeCubit>().selectNode(null);
                            context.read<FaultTreeCubit>().cancelConnecting();
                            context.read<FaultTreeCubit>().clearPendingSource();
                          },
                          child: const _GridBackground(),
                        ),
                      ),

                      // Connection Lines
                      const Positioned.fill(child: _ConnectionLayer()),

                      // Nodes
                      _NodeLayer(
                        onDragStart: () => _setPanEnabled(false),
                        onDragEnd: () => _setPanEnabled(true),
                        transformationController: _transformationController,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Tap-to-connect status bar
          Positioned(
            top: 16,
            left: 16,
            right: 80,
            child: BlocBuilder<FaultTreeCubit, FaultTreeState>(
              buildWhen: (p, c) =>
                  p.pendingConnectionSource != c.pendingConnectionSource ||
                  p.rejectedNodeId != c.rejectedNodeId ||
                  p.lastConnectedSourceId != c.lastConnectedSourceId,
              builder: (context, state) {
                if (state.pendingConnectionSource != null) {
                  return _StatusChip(
                    label: 'Tap another node to connect',
                    color: const Color(0xFF3DA229),
                    icon: Icons.touch_app,
                  );
                }
                if (state.rejectedNodeId != null) {
                  final msg = switch (state.rejectionReason) {
                    ConnectionRejection.eventAlreadyHasParent =>
                      'Event already has a parent',
                    ConnectionRejection.gateAlreadyHasOutgoing =>
                      'Gate already has an outgoing link',
                    ConnectionRejection.selfConnection =>
                      'Cannot connect to self',
                    ConnectionRejection.duplicateConnection =>
                      'Connection already exists',
                    null => 'Invalid connection',
                  };
                  return _StatusChip(
                    label: msg,
                    color: Colors.red,
                    icon: Icons.block,
                  );
                }
                if (state.lastConnectedSourceId != null) {
                  return _StatusChip(
                    label: 'Connected!',
                    color: const Color(0xFF3DA229),
                    icon: Icons.check_circle,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Undo/Redo Controls (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                _ControlButton(
                  icon: Icons.undo,
                  onPressed: () => context.read<FaultTreeCubit>().undo(),
                ),
                const SizedBox(width: 12),
                _ControlButton(
                  icon: Icons.redo,
                  onPressed: () => context.read<FaultTreeCubit>().redo(),
                ),
              ],
            ),
          ),

          // Tools Sidebar (Bottom Right)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                BlocBuilder<FaultTreeCubit, FaultTreeState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        _ToolButton(
                          icon: Icons.add_box_outlined,
                          onPressed: () =>
                              context.read<FaultTreeCubit>().addNode(
                                FaultTreeNodeType.event,
                                _getCenterOffset(),
                              ),
                          color: const Color(0xFF3DA229),
                          tooltip: 'Event',
                        ),
                        const SizedBox(height: 12),
                        _ToolButton(
                          icon: Icons.circle_outlined,
                          onPressed: () =>
                              context.read<FaultTreeCubit>().addNode(
                                FaultTreeNodeType.andGate,
                                _getCenterOffset(),
                              ),
                          color: const Color(0xFF3DA229),
                          tooltip: 'AND Gate',
                        ),
                        const SizedBox(height: 12),
                        _ToolButton(
                          icon: Icons.change_history_outlined,
                          onPressed: () =>
                              context.read<FaultTreeCubit>().addNode(
                                FaultTreeNodeType.orGate,
                                _getCenterOffset(),
                              ),
                          color: const Color(0xFF3DA229),
                          tooltip: 'OR Gate',
                        ),
                        const SizedBox(height: 12),
                        _ToolButton(
                          icon: Icons.delete_outline,
                          onPressed: state.selectedNodeId != null
                              ? () => context.read<FaultTreeCubit>().deleteNode(
                                  state.selectedNodeId!,
                                )
                              : null,
                          color: Colors.red.withValues(alpha: 0.6),
                          isDisabled: state.selectedNodeId == null,
                          tooltip: 'Delete',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _getCenterOffset() {
    if (_lastConstraints == null) return const Offset(400, 200);

    // Get the center of the visible widget
    final viewportCenter = Offset(
      _lastConstraints!.maxWidth / 2,
      _lastConstraints!.maxHeight / 2,
    );

    // Transform viewport center to canvas coordinates
    final Matrix4 matrix = _transformationController.value;
    final Matrix4 inverted = Matrix4.inverted(matrix);

    final vector_math.Vector3 centerVector = vector_math.Vector3(
      viewportCenter.dx,
      viewportCenter.dy,
      0,
    );
    final vector_math.Vector3 transformed = inverted.transform3(centerVector);

    // Subtract half node size to truly center the node
    return Offset(transformed.x - 90, transformed.y - 45);
  }

  static Offset screenToCanvas(
    Offset screenPoint,
    TransformationController controller,
  ) {
    final Matrix4 matrix = controller.value;
    final Matrix4 inverted = Matrix4.inverted(matrix);
    final vector_math.Vector3 vector = vector_math.Vector3(
      screenPoint.dx,
      screenPoint.dy,
      0,
    );
    final vector_math.Vector3 transformed = inverted.transform3(vector);
    return Offset(transformed.x, transformed.y);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATUS CHIP (shows tap-to-connect state feedback)
// ═══════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GRID BACKGROUND
// ═══════════════════════════════════════════════════════════════════

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3DA229).withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  NODE LAYER (with tap-to-connect interaction)
// ═══════════════════════════════════════════════════════════════════

class _NodeLayer extends StatelessWidget {
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final TransformationController transformationController;

  const _NodeLayer({
    required this.onDragStart,
    required this.onDragEnd,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaultTreeCubit, FaultTreeState>(
      builder: (context, state) {
        return Stack(
          children: state.nodes.map((node) {
            final isPendingSource = state.pendingConnectionSource == node.id;
            final isRejected = state.rejectedNodeId == node.id;
            final isSuccessSource = state.lastConnectedSourceId == node.id;
            final isSuccessTarget = state.lastConnectedTargetId == node.id;

            return Positioned(
              left: node.position.dx,
              top: node.position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => onDragStart(),
                onPanUpdate: (details) {
                  final scale = transformationController.value
                      .getMaxScaleOnAxis();
                  context.read<FaultTreeCubit>().moveNode(
                    node.id,
                    node.position + (details.delta / scale),
                  );
                },
                onPanEnd: (_) {
                  onDragEnd();
                  context.read<FaultTreeCubit>().endMoveNode();
                },
                onTap: () {
                  // Use the tap-to-connect flow
                  context.read<FaultTreeCubit>().tapNode(node.id);
                },
                child: _FaultTreeNodeWidget(
                  node: node,
                  isSelected: state.selectedNodeId == node.id,
                  isPendingSource: isPendingSource,
                  isRejected: isRejected,
                  isSuccessSource: isSuccessSource,
                  isSuccessTarget: isSuccessTarget,
                  isActive:
                      state.isConnecting &&
                      state.connectionStartNodeId == node.id,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NODE WIDGET (dispatches to Event / Gate with visual states)
// ═══════════════════════════════════════════════════════════════════

class _FaultTreeNodeWidget extends StatelessWidget {
  final FaultTreeNode node;
  final bool isSelected;
  final bool isActive;
  final bool isPendingSource;
  final bool isRejected;
  final bool isSuccessSource;
  final bool isSuccessTarget;

  const _FaultTreeNodeWidget({
    required this.node,
    this.isSelected = false,
    this.isActive = false,
    this.isPendingSource = false,
    this.isRejected = false,
    this.isSuccessSource = false,
    this.isSuccessTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (node.type) {
      case FaultTreeNodeType.event:
        return _EventNode(
          node: node,
          isSelected: isSelected,
          isActive: isActive,
          isPendingSource: isPendingSource,
          isRejected: isRejected,
          isSuccess: isSuccessSource || isSuccessTarget,
        );
      case FaultTreeNodeType.andGate:
        return _GateNode(
          label: 'AND',
          isSelected: isSelected,
          isActive: isActive,
          node: node,
          isPendingSource: isPendingSource,
          isRejected: isRejected,
          isSuccess: isSuccessSource || isSuccessTarget,
        );
      case FaultTreeNodeType.orGate:
        return _GateNode(
          label: 'OR',
          isSelected: isSelected,
          isActive: isActive,
          node: node,
          isPendingSource: isPendingSource,
          isRejected: isRejected,
          isSuccess: isSuccessSource || isSuccessTarget,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EVENT NODE
// ═══════════════════════════════════════════════════════════════════

class _EventNode extends StatelessWidget {
  final FaultTreeNode node;
  final bool isSelected;
  final bool isActive;
  final bool isPendingSource;
  final bool isRejected;
  final bool isSuccess;

  const _EventNode({
    required this.node,
    required this.isSelected,
    required this.isActive,
    required this.isPendingSource,
    required this.isRejected,
    required this.isSuccess,
  });

  Color get _borderColor {
    if (isRejected) return Colors.red;
    if (isSuccess) return const Color(0xFF2E7D32);
    if (isPendingSource) return const Color(0xFF1565C0);
    if (isSelected) return const Color(0xFF3DA229);
    return const Color(0xFF3DA229).withValues(alpha: 0.3);
  }

  double get _borderWidth {
    if (isRejected || isPendingSource || isSuccess) return 2.5;
    if (isSelected) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPendingSource
            ? const Color(0xFFE3F2FD)
            : isRejected
            ? const Color(0xFFFFEBEE)
            : isSuccess
            ? const Color(0xFFE8F5E9)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: _borderWidth),
        boxShadow: [
          BoxShadow(
            color: isPendingSource
                ? const Color(0xFF1565C0).withValues(alpha: 0.15)
                : isRejected
                ? Colors.red.withValues(alpha: 0.15)
                : isSuccess
                ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isPendingSource || isRejected || isSuccess ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.label.isNotEmpty ? node.label : 'Chemical Leak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isPendingSource)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              if (isRejected)
                const Icon(Icons.block, size: 14, color: Colors.red),
              if (isSuccess)
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF2E7D32),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            node.subtitle.isNotEmpty
                ? node.subtitle
                : 'it down into contributing failures.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                node.tag ?? 'Equipment',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF3F51B5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GATE NODE (AND / OR)
// ═══════════════════════════════════════════════════════════════════

class _GateNode extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isActive;
  final FaultTreeNode node;
  final bool isPendingSource;
  final bool isRejected;
  final bool isSuccess;

  const _GateNode({
    required this.label,
    required this.isSelected,
    required this.isActive,
    required this.node,
    required this.isPendingSource,
    required this.isRejected,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(60, 40),
            painter: _GatePainter(
              label: label,
              isSelected: isSelected,
              color: const Color(0xFF3DA229),
              isPendingSource: isPendingSource,
              isRejected: isRejected,
              isSuccess: isSuccess,
            ),
          ),
          if (isPendingSource)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SOURCE',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GatePainter extends CustomPainter {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isPendingSource;
  final bool isRejected;
  final bool isSuccess;

  _GatePainter({
    required this.label,
    required this.isSelected,
    required this.color,
    this.isPendingSource = false,
    this.isRejected = false,
    this.isSuccess = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Color fillColor;
    Color borderColor;
    double strokeWidth;

    if (isRejected) {
      fillColor = const Color(0xFFFFEBEE);
      borderColor = Colors.red;
      strokeWidth = 2.5;
    } else if (isPendingSource) {
      fillColor = const Color(0xFFE3F2FD);
      borderColor = const Color(0xFF1565C0);
      strokeWidth = 2.5;
    } else if (isSuccess) {
      fillColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF2E7D32);
      strokeWidth = 2.5;
    } else if (isSelected) {
      fillColor = Colors.white;
      borderColor = color;
      strokeWidth = 2;
    } else {
      fillColor = Colors.white;
      borderColor = Colors.black.withValues(alpha: 0.5);
      strokeWidth = 1;
    }

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    if (label == 'AND') {
      path.moveTo(size.width * 0.1, 0);
      path.lineTo(size.width * 0.6, 0);
      path.arcToPoint(
        Offset(size.width * 0.6, size.height),
        radius: Radius.circular(size.height / 2),
        clockwise: true,
      );
      path.lineTo(size.width * 0.1, size.height);
      path.quadraticBezierTo(
        size.width * 0.3,
        size.height / 2,
        size.width * 0.1,
        0,
      );
      path.close();
    } else {
      // OR gate as a diamond
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width * 0.9, size.height / 2);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width * 0.1, size.height / 2);
      path.close();
    }

    // Draw glow for pending source
    if (isPendingSource) {
      final glowPaint = Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isPendingSource
              ? const Color(0xFF1565C0)
              : Colors.black.withValues(alpha: 0.8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════
//  CONNECTION LAYER (curved orthogonal + arrowheads)
// ═══════════════════════════════════════════════════════════════════

class _ConnectionLayer extends StatelessWidget {
  const _ConnectionLayer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaultTreeCubit, FaultTreeState>(
      builder: (context, state) {
        return CustomPaint(
          painter: _ConnectionPainter(
            nodes: state.nodes,
            connections: state.connections,
            draggingEnd: state.draggingConnectionEnd,
            draggingStartId: state.connectionStartNodeId,
            pendingSourceId: state.pendingConnectionSource,
            lastConnectedSourceId: state.lastConnectedSourceId,
            lastConnectedTargetId: state.lastConnectedTargetId,
          ),
        );
      },
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  final List<FaultTreeNode> nodes;
  final List<FaultTreeConnection> connections;
  final Offset? draggingEnd;
  final String? draggingStartId;
  final String? pendingSourceId;
  final String? lastConnectedSourceId;
  final String? lastConnectedTargetId;

  _ConnectionPainter({
    required this.nodes,
    required this.connections,
    this.draggingEnd,
    this.draggingStartId,
    this.pendingSourceId,
    this.lastConnectedSourceId,
    this.lastConnectedTargetId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      FaultTreeNode? fromNode;
      FaultTreeNode? toNode;
      for (final n in nodes) {
        if (n.id == conn.fromNodeId) fromNode = n;
        if (n.id == conn.toNodeId) toNode = n;
      }
      if (fromNode == null || toNode == null) continue;

      // fromNode = child (source), toNode = parent (target)
      // Arrow points toward parent = toward toNode
      final start = _getNodePoint(fromNode, isBottom: false); // top of child
      final end = _getNodePoint(toNode, isBottom: true); // bottom of parent

      // Highlight newly connected link
      final isNewlyConnected =
          (conn.fromNodeId == lastConnectedSourceId &&
          conn.toNodeId == lastConnectedTargetId);

      final paint = Paint()
        ..color = isNewlyConnected
            ? const Color(0xFF2E7D32)
            : Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isNewlyConnected ? 2.5 : 1.5;

      final path = _buildOrthogonalPath(start, end);
      canvas.drawPath(path, paint);

      // Draw arrowhead pointing toward parent (at end point)
      _drawArrowhead(
        canvas,
        start,
        end,
        isNewlyConnected
            ? const Color(0xFF2E7D32)
            : Colors.black.withValues(alpha: 0.4),
      );
    }

    // Draw preview line during drag-connect
    if (draggingEnd != null && draggingStartId != null) {
      FaultTreeNode? fromNode;
      for (final n in nodes) {
        if (n.id == draggingStartId) {
          fromNode = n;
          break;
        }
      }
      if (fromNode != null) {
        final start = _getNodePoint(fromNode, isBottom: true);
        final end = draggingEnd!;

        final previewPaint = Paint()
          ..color = const Color(0xFF3DA229).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        final path = _buildOrthogonalPath(start, end);
        canvas.drawPath(path, previewPaint);
      }
    }

    // Draw pending source indicator (pulsing circle at node bottom)
    if (pendingSourceId != null) {
      FaultTreeNode? sourceNode;
      for (final n in nodes) {
        if (n.id == pendingSourceId) {
          sourceNode = n;
          break;
        }
      }
      if (sourceNode != null) {
        final bottom = _getNodePoint(sourceNode, isBottom: false);
        final indicatorPaint = Paint()
          ..color = const Color(0xFF1565C0).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(bottom, 8, indicatorPaint);

        final ringPaint = Paint()
          ..color = const Color(0xFF1565C0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(bottom, 8, ringPaint);
      }
    }
  }

  /// Build a curved orthogonal path from [start] to [end].
  /// The path goes: vertical → curved corner → horizontal → curved corner → vertical.
  Path _buildOrthogonalPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final midY = (start.dy + end.dy) / 2;
    final cornerRadius = 16.0;
    final dx = (end.dx - start.dx).abs();
    final dy = (midY - start.dy).abs();

    // If nodes are almost vertically aligned, draw a straight line
    if (dx < 2) {
      path.lineTo(end.dx, end.dy);
      return path;
    }

    // Clamp corner radius
    final effectiveR = math.min(cornerRadius, math.min(dx / 2, dy));

    // Vertical line from start to midY
    path.lineTo(start.dx, midY - effectiveR);

    // First curve (horizontal corner)
    if (end.dx > start.dx) {
      path.quadraticBezierTo(start.dx, midY, start.dx + effectiveR, midY);
    } else {
      path.quadraticBezierTo(start.dx, midY, start.dx - effectiveR, midY);
    }

    // Horizontal line to end.dx
    if (end.dx > start.dx) {
      path.lineTo(end.dx - effectiveR, midY);
    } else {
      path.lineTo(end.dx + effectiveR, midY);
    }

    // Second curve (vertical corner)
    path.quadraticBezierTo(end.dx, midY, end.dx, midY + effectiveR);

    // Vertical line to end
    path.lineTo(end.dx, end.dy);

    return path;
  }

  /// Draw an arrowhead at [end], pointing from [start] direction toward [end].
  void _drawArrowhead(Canvas canvas, Offset start, Offset end, Color color) {
    // Determine the direction of the last segment (vertical toward end)
    // The line always ends going vertically into the parent, so arrow points upward or downward.
    final isGoingUp = end.dy < start.dy;
    final angle = isGoingUp ? -math.pi / 2 : math.pi / 2;

    final arrowSize = 8.0;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final p1 = end;
    final p2 = Offset(
      end.dx - arrowSize * math.cos(angle - 0.5),
      end.dy - arrowSize * math.sin(angle - 0.5),
    );
    final p3 = Offset(
      end.dx - arrowSize * math.cos(angle + 0.5),
      end.dy - arrowSize * math.sin(angle + 0.5),
    );

    final arrowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  Offset _getNodePoint(FaultTreeNode node, {required bool isBottom}) {
    double width = (node.type == FaultTreeNodeType.event) ? 180 : 60;
    double height = (node.type == FaultTreeNodeType.event) ? 90 : 40;

    if (isBottom) {
      return Offset(node.position.dx + width / 2, node.position.dy + height);
    } else {
      return Offset(node.position.dx + width / 2, node.position.dy);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════
//  CONTROL BUTTONS
// ═══════════════════════════════════════════════════════════════════

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: const Color(0xFF3DA229)),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isDisabled;
  final bool isActive;
  final String? tooltip;

  const _ToolButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isDisabled = false,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.1)
              : (isActive ? Colors.red : color),
          shape: BoxShape.circle,
          boxShadow: [
            if (!isDisabled)
              BoxShadow(
                color: (isActive ? Colors.red : color).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, size: 22, color: Colors.white),
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
