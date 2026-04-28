import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../data/model/fault_tree_model.dart';

/// Describes why a connection was rejected
enum ConnectionRejection {
  eventAlreadyHasParent,
  gateAlreadyHasOutgoing,
  selfConnection,
  duplicateConnection,
}

class FaultTreeState extends Equatable {
  final List<FaultTreeNode> nodes;
  final List<FaultTreeConnection> connections;
  final String? selectedNodeId;

  // Legacy drag-connect support (kept for toolbar button compatibility)
  final bool isConnecting;
  final String? connectionStartNodeId;
  final Offset? draggingConnectionEnd;

  // Tap-to-connect flow
  final String? pendingConnectionSource;

  // Rejection feedback
  final String? rejectedNodeId;
  final ConnectionRejection? rejectionReason;

  // Success flash
  final String? lastConnectedSourceId;
  final String? lastConnectedTargetId;

  const FaultTreeState({
    this.nodes = const [],
    this.connections = const [],
    this.selectedNodeId,
    this.isConnecting = false,
    this.connectionStartNodeId,
    this.draggingConnectionEnd,
    this.pendingConnectionSource,
    this.rejectedNodeId,
    this.rejectionReason,
    this.lastConnectedSourceId,
    this.lastConnectedTargetId,
  });

  FaultTreeState copyWith({
    List<FaultTreeNode>? nodes,
    List<FaultTreeConnection>? connections,
    String? selectedNodeId,
    bool? isConnecting,
    String? connectionStartNodeId,
    Offset? draggingConnectionEnd,
    String? pendingConnectionSource,
    String? rejectedNodeId,
    ConnectionRejection? rejectionReason,
    String? lastConnectedSourceId,
    String? lastConnectedTargetId,
  }) {
    return FaultTreeState(
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
      selectedNodeId: selectedNodeId,
      isConnecting: isConnecting ?? this.isConnecting,
      connectionStartNodeId:
          connectionStartNodeId ?? this.connectionStartNodeId,
      draggingConnectionEnd:
          draggingConnectionEnd ?? this.draggingConnectionEnd,
      pendingConnectionSource: pendingConnectionSource,
      rejectedNodeId: rejectedNodeId,
      rejectionReason: rejectionReason,
      lastConnectedSourceId: lastConnectedSourceId,
      lastConnectedTargetId: lastConnectedTargetId,
    );
  }

  @override
  List<Object?> get props => [
    nodes,
    connections,
    selectedNodeId,
    isConnecting,
    connectionStartNodeId,
    draggingConnectionEnd,
    pendingConnectionSource,
    rejectedNodeId,
    rejectionReason,
    lastConnectedSourceId,
    lastConnectedTargetId,
  ];
}

class FaultTreeCubit extends Cubit<FaultTreeState> {
  final List<FaultTreeState> _history = [];
  int _historyIndex = -1;

  FaultTreeCubit() : super(const FaultTreeState()) {
    _saveToHistory();
  }

  void _saveToHistory() {
    // Remove future history if we're in the middle of undoing
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(state);
    _historyIndex = _history.length - 1;
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      emit(_history[_historyIndex]);
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      emit(_history[_historyIndex]);
    }
  }

  void addNode(FaultTreeNodeType type, Offset position) {
    final newNode = FaultTreeNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      position: position,
      label: type == FaultTreeNodeType.event ? 'New Event' : '',
    );

    emit(state.copyWith(nodes: [...state.nodes, newNode]));
    _saveToHistory();
  }

  void moveNode(String nodeId, Offset newPosition) {
    final updatedNodes = state.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(position: newPosition);
      }
      return node;
    }).toList();

    emit(state.copyWith(nodes: updatedNodes));
  }

  // Called when drag ends to save state to history
  void endMoveNode() {
    _saveToHistory();
  }

  void selectNode(String? nodeId) {
    emit(state.copyWith(selectedNodeId: nodeId));
  }

  void deleteNode(String nodeId) {
    final updatedNodes = state.nodes
        .where((node) => node.id != nodeId)
        .toList();
    final updatedConnections = state.connections
        .where((conn) => conn.fromNodeId != nodeId && conn.toNodeId != nodeId)
        .toList();

    emit(
      state.copyWith(
        nodes: updatedNodes,
        connections: updatedConnections,
        selectedNodeId: state.selectedNodeId == nodeId
            ? null
            : state.selectedNodeId,
      ),
    );
    _saveToHistory();
  }

  // ────────────────────────────────────────────────────────────────
  // TAP-TO-CONNECT FLOW
  // ────────────────────────────────────────────────────────────────

  /// Called when a user taps any node on the canvas.
  ///
  /// **Tap 1** – Sets this node as the pending connection source.
  /// **Tap 2** – Validates and creates the connection, then resets.
  void tapNode(String nodeId) {
    // ── Tap 1: No pending source → set this node as source ──
    if (state.pendingConnectionSource == null) {
      emit(
        state.copyWith(
          pendingConnectionSource: nodeId,
          selectedNodeId: nodeId,
          // Clear any previous feedback
          rejectedNodeId: null,
          rejectionReason: null,
          lastConnectedSourceId: null,
          lastConnectedTargetId: null,
        ),
      );
      return;
    }

    final sourceId = state.pendingConnectionSource!;

    // ── Same node tapped again → deselect / cancel ──
    if (sourceId == nodeId) {
      emit(
        state.copyWith(
          pendingConnectionSource: null,
          selectedNodeId: null,
          rejectedNodeId: null,
          rejectionReason: null,
        ),
      );
      return;
    }

    // ── Tap 2: Validate & connect ──
    final rejection = _validateConnection(sourceId, nodeId);

    if (rejection != null) {
      // Show visual rejection on the target node
      emit(
        state.copyWith(
          rejectedNodeId: nodeId,
          rejectionReason: rejection,
          // Keep source selected so user can try another target
        ),
      );
      // Auto-clear rejection after a brief moment (the widget layer
      // will handle the animation; we just reset state soon).
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!isClosed && state.rejectedNodeId == nodeId) {
          emit(state.copyWith(rejectedNodeId: null, rejectionReason: null));
        }
      });
      return;
    }

    // Passed validation → create connection
    final newConnection = FaultTreeConnection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromNodeId: sourceId,
      toNodeId: nodeId,
    );

    emit(
      state.copyWith(
        connections: [...state.connections, newConnection],
        pendingConnectionSource: null,
        selectedNodeId: null,
        rejectedNodeId: null,
        rejectionReason: null,
        lastConnectedSourceId: sourceId,
        lastConnectedTargetId: nodeId,
      ),
    );
    _saveToHistory();

    // Clear success flash
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!isClosed &&
          state.lastConnectedSourceId == sourceId &&
          state.lastConnectedTargetId == nodeId) {
        emit(
          state.copyWith(
            lastConnectedSourceId: null,
            lastConnectedTargetId: null,
          ),
        );
      }
    });
  }

  /// Validates whether a connection from [sourceId] → [targetId] is allowed.
  /// Returns `null` if valid, otherwise a [ConnectionRejection].
  ///
  /// **Connection rules (Fault Tree logic):**
  /// * A connection goes from a **child** (source) upward to a **parent** (target).
  /// * fromNode = source (child), toNode = target (parent).
  ///
  /// 1. Event nodes can have only **one incoming** connection (one parent).
  ///    → The *source* (child) event must not already have an outgoing connection
  ///      that makes the **target** have >1 parent — no, the target gets one more
  ///      incoming.
  ///
  /// Reworded rules matching the spec:
  ///   - **Event node**: max 1 incoming (parent) connection. Multiple outgoing OK.
  ///   - **AND/OR gate**: multiple incoming OK. Max 1 outgoing connection.
  ///
  /// In our data model:
  ///   `fromNodeId` = child (source)  →  `toNodeId` = parent (target)
  ///   "incoming" to a node = connections where `toNodeId == node.id`
  ///   "outgoing" from a node = connections where `fromNodeId == node.id`
  ConnectionRejection? _validateConnection(String sourceId, String targetId) {
    if (sourceId == targetId) return ConnectionRejection.selfConnection;

    // Check for duplicate
    final alreadyExists = state.connections.any(
      (c) => c.fromNodeId == sourceId && c.toNodeId == targetId,
    );
    if (alreadyExists) return ConnectionRejection.duplicateConnection;

    final sourceNode = state.nodes.firstWhere((n) => n.id == sourceId);
    final targetNode = state.nodes.firstWhere((n) => n.id == targetId);

    // Count existing outgoing connections from source
    final sourceOutgoingCount = state.connections
        .where((c) => c.fromNodeId == sourceId)
        .length;

    // Count existing incoming connections to target
    final targetIncomingCount = state.connections
        .where((c) => c.toNodeId == targetId)
        .length;

    // Rule: AND/OR gate can have only 1 outgoing connection
    if (sourceNode.isGate && sourceOutgoingCount >= 1) {
      return ConnectionRejection.gateAlreadyHasOutgoing;
    }

    // Rule: Event node can have only 1 incoming (parent) connection
    if (targetNode.type == FaultTreeNodeType.event &&
        targetIncomingCount >= 1) {
      return ConnectionRejection.eventAlreadyHasParent;
    }

    return null; // Valid
  }

  /// Clear the pending source without changing selection
  void clearPendingSource() {
    emit(
      state.copyWith(
        pendingConnectionSource: null,
        rejectedNodeId: null,
        rejectionReason: null,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // LEGACY DRAG-CONNECT (kept for toolbar compatibility)
  // ────────────────────────────────────────────────────────────────

  void startConnecting(String nodeId, Offset startPosition) {
    emit(
      state.copyWith(
        isConnecting: true,
        connectionStartNodeId: nodeId,
        draggingConnectionEnd: startPosition,
      ),
    );
  }

  void updateDraggingConnection(Offset endPosition) {
    emit(state.copyWith(draggingConnectionEnd: endPosition));
  }

  void connectToNode(String targetNodeId) {
    if (state.connectionStartNodeId != null &&
        state.connectionStartNodeId != targetNodeId) {
      final rejection = _validateConnection(
        state.connectionStartNodeId!,
        targetNodeId,
      );

      if (rejection == null) {
        final newConnection = FaultTreeConnection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromNodeId: state.connectionStartNodeId!,
          toNodeId: targetNodeId,
        );

        emit(
          state.copyWith(
            connections: [...state.connections, newConnection],
            isConnecting: false,
            connectionStartNodeId: null,
            draggingConnectionEnd: null,
          ),
        );
        _saveToHistory();
        return;
      }
    }

    cancelConnecting();
  }

  void cancelConnecting() {
    emit(
      state.copyWith(
        isConnecting: false,
        connectionStartNodeId: null,
        draggingConnectionEnd: null,
      ),
    );
  }

  void updateNodeLabel(
    String nodeId,
    String label, {
    String? subtitle,
    String? tag,
  }) {
    final updatedNodes = state.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(label: label, subtitle: subtitle, tag: tag);
      }
      return node;
    }).toList();

    emit(state.copyWith(nodes: updatedNodes));
    _saveToHistory();
  }
}
