class CreateChatGroupRequest {
  final String incidentId;

  CreateChatGroupRequest({
    required this.incidentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
    };
  }
}

class AddMemberRequest {
  final String groupId;
  final String userId;

  AddMemberRequest({
    required this.groupId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'userId': userId,
    };
  }
}

class RemoveMemberRequest {
  final String groupId;
  final String userId;

  RemoveMemberRequest({
    required this.groupId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'userId': userId,
    };
  }
}
