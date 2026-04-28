import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum FaultTreeNodeType { event, andGate, orGate }

class FaultTreeNode extends Equatable {
  final String id;
  final String label;
  final String subtitle;
  final String? tag;
  final Offset position;
  final FaultTreeNodeType type;

  const FaultTreeNode({
    required this.id,
    this.label = '',
    this.subtitle = '',
    this.tag,
    required this.position,
    required this.type,
  });

  FaultTreeNode copyWith({
    String? label,
    String? subtitle,
    String? tag,
    Offset? position,
    FaultTreeNodeType? type,
  }) {
    return FaultTreeNode(
      id: id,
      label: label ?? this.label,
      subtitle: subtitle ?? this.subtitle,
      tag: tag ?? this.tag,
      position: position ?? this.position,
      type: type ?? this.type,
    );
  }

  bool get isGate =>
      type == FaultTreeNodeType.andGate || type == FaultTreeNodeType.orGate;

  @override
  List<Object?> get props => [id, label, subtitle, tag, position, type];
}

class FaultTreeConnection extends Equatable {
  final String id;
  final String fromNodeId;
  final String toNodeId;

  const FaultTreeConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
  });

  @override
  List<Object?> get props => [id, fromNodeId, toNodeId];
}
