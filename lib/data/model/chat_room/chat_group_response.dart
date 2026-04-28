import 'package:emergex/data/model/call_models.dart';

class CreateChatGroupResponse {
  final ChatGroup? chatGroup;
  final List<ChatMember>? members;
  final bool? alreadyExists;
  final ActiveCall? activeCall;

  CreateChatGroupResponse({
    this.chatGroup,
    this.members,
    this.alreadyExists,
    this.activeCall,
  });

  factory CreateChatGroupResponse.fromJson(Map<String, dynamic> json) {
    return CreateChatGroupResponse(
      chatGroup: json['chatGroup'] != null
          ? ChatGroup.fromJson(json['chatGroup'] as Map<String, dynamic>)
          : null,
      members: json['members'] is List
          ? (json['members'] as List)
                .map((e) => ChatMember.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      alreadyExists: json['alreadyExists'] as bool?,
      activeCall: json['activeCall'] != null
          ? ActiveCall.fromJson(json['activeCall'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatGroup': chatGroup?.toJson(),
      'members': members?.map((e) => e.toJson()).toList(),
      'alreadyExists': alreadyExists,
      'activeCall': activeCall?.toJson(),
    };
  }
}

class ChatGroup {
  final String? id;
  final String? name;
  final String? incident;
  final String? createdBy;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  ChatGroup({
    this.id,
    this.name,
    this.incident,
    this.createdBy,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'] as String?,
      name: json['name'] as String?,
      incident: json['incident'] as String?,
      createdBy: json['createdBy'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'incident': incident,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ChatGroup copyWith({
    String? id,
    String? name,
    String? incident,
    String? createdBy,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return ChatGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      incident: incident ?? this.incident,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserDetails {
  final String? id;
  final String? name;
  final String? email;

  UserDetails({this.id, this.name, this.email});

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

class ChatMember {
  final String? id;
  final String? chatGroup;
  final dynamic user;
  final String? role;
  final bool? isActive;
  final String? joinedAt;
  final String? leftAt;

  UserDetails? userDetails;
  String? userId;

  /// Direct userName from flat JSON response (e.g., from createChatGroup API)
  final String? _userName;

  /// Direct userEmail from flat JSON response (e.g., from createChatGroup API)
  final String? userEmail;

  /// Get user's display name - prioritizes direct userName, then userDetails.name
  String? get userName => _userName ?? userDetails?.name;

  /// Alias for userName - get user's display name
  String? get name => _userName ?? userDetails?.name;

  ChatMember({
    this.id,
    this.chatGroup,
    this.user,
    this.role,
    this.isActive,
    this.joinedAt,
    this.leftAt,
    String? userName,
    this.userEmail,
  }) : _userName = userName {
    if (user is String) {
      userId = user as String?;
    } else if (user is Map<String, dynamic>) {
      userDetails = UserDetails.fromJson(user as Map<String, dynamic>);
      userId = userDetails?.id;
    }
  }

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      id: json['id'] as String?,
      chatGroup: json['chatGroup'] as String?,
      user: json['user'],
      role: json['role'] as String?,
      isActive: json['isActive'] as bool?,
      joinedAt: json['joinedAt'] as String?,
      leftAt: json['leftAt'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatGroup': chatGroup,
      'user': user is String
          ? user
          : (userDetails != null ? userDetails!.toJson() : user),
      'role': role,
      'isActive': isActive,
      'joinedAt': joinedAt,
      'leftAt': leftAt,
    };
  }

  ChatMember copyWith({
    String? id,
    String? chatGroup,
    dynamic user,
    String? role,
    bool? isActive,
    String? joinedAt,
    String? leftAt,
    String? userName,
    String? userEmail,
  }) {
    return ChatMember(
      id: id ?? this.id,
      chatGroup: chatGroup ?? this.chatGroup,
      user: user ?? this.user,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      userName: userName ?? _userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
