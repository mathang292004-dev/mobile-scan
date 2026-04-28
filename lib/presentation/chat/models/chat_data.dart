import 'chat_message_model.dart';
import 'chat_member_model.dart';

/// Static mock data for chat messages and members
/// This will be replaced with API calls in the future
class ChatData {
  /// Mock incident information
  static const String incidentId = '#IR-103';
  static const int onlineCount = 5;
  static const int totalMembers = 12;

  /// Mock chat messages
  static List<ChatMessage> get mockMessages => [
    ChatMessage(
      id: '1',
      senderId: 'user1',
      senderName: 'Anthony Parker',
      senderAvatar:
          'http://localhost:3845/assets/4b66197f9eb7e0792df1f70079064ea2dc357fc6.png',
      message:
          'Scaffold at Zone 3 collapsed during inspection. No one injured, but area is unsafe.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: true,
    ),
    ChatMessage(
      id: '2',
      senderId: 'currentUser',
      senderName: 'You',
      senderAvatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      message: 'Confirming all personnel are clear. Barricades are up.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: true,
      isOnline: true,
    ),
    ChatMessage(
      id: '3',
      senderId: 'user2',
      senderName: 'Pete Hamilton',
      senderAvatar:
          'http://localhost:3845/assets/0a16cb0e41db33331f39452bcb2488e5873e3a3e.png',
      message:
          'Preliminary check indicates base instability may have caused it. Need full structural review.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: true,
    ),
    ChatMessage(
      id: '4',
      senderId: 'user3',
      senderName: 'Coleman',
      senderAvatar:
          'http://localhost:3845/assets/d9507786c8d804464ff9ed4185c7c3dde2675563.png',
      message:
          'Notifying management and safety team. Temporary scaffolding review scheduled.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: true,
    ),
    ChatMessage(
      id: '5',
      senderId: 'user4',
      senderName: 'Sandra',
      senderAvatar:
          'http://localhost:3845/assets/30a03b20d0d79bd9c491d22b6f3398fcaedf2780.png',
      message: 'Will prepare incident report including root cause analysis.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: false,
    ),
    ChatMessage(
      id: '6',
      senderId: 'currentUser',
      senderName: 'You',
      senderAvatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      message:
          'Found last inspection report – notes minor base leveling issue, but wasn\'t marked critical.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: true,
      isOnline: true,
    ),
    ChatMessage(
      id: '7',
      senderId: 'user3',
      senderName: 'Coleman',
      senderAvatar:
          'http://localhost:3845/assets/d9507786c8d804464ff9ed4185c7c3dde2675563.png',
      message:
          'Consider scheduling follow-up inspections periodically to ensure stability.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: true,
    ),
    ChatMessage(
      id: '8',
      senderId: 'user4',
      senderName: 'Sandra',
      senderAvatar:
          'http://localhost:3845/assets/30a03b20d0d79bd9c491d22b6f3398fcaedf2780.png',
      message: 'Will prepare incident report including root cause analysis.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: false,
    ),
    ChatMessage(
      id: '9',
      senderId: 'currentUser',
      senderName: 'You',
      senderAvatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      message: 'Confirming all personnel are clear. Barricades are up.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: true,
      isOnline: true,
    ),
    ChatMessage(
      id: '10',
      senderId: 'user1',
      senderName: 'Anthony Parker',
      senderAvatar:
          'http://localhost:3845/assets/4b66197f9eb7e0792df1f70079064ea2dc357fc6.png',
      message:
          'Documenting photos and measurements. Keep area restricted until investigation complete.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: true,
    ),
    ChatMessage(
      id: '11',
      senderId: 'user4',
      senderName: 'Sandra',
      senderAvatar:
          'http://localhost:3845/assets/30a03b20d0d79bd9c491d22b6f3398fcaedf2780.png',
      message: 'Will prepare incident report including root cause analysis.',
      timestamp: DateTime(2025, 10, 27, 10, 52),
      isMe: false,
      isOnline: false,
    ),
  ];

  /// Mock team members (already in chat)
  static List<ChatMember> get mockTeamMembers => [
    ChatMember(
      id: 'member1',
      name: 'Alice Smith',
      email: 'alicesmith@example.com',
      avatar:
          'http://localhost:3845/assets/89d881d88e86de45745f2e2e658a88178708270f.png',
      role: 'Safety Officer',
      team: 'ER Team',
      isOnline: true,
      isTeamMember: true,
      contactNumber: '+1234567890',
    ),
    ChatMember(
      id: 'member2',
      name: 'John Doe',
      email: 'alicesmith@example.com',
      avatar:
          'http://localhost:3845/assets/a099d84a692d83c6dedc0845cc99da4d9f97e0fb.png',
      role: 'Engineer',
      team: 'ER Team',
      isOnline: false,
      isTeamMember: true,
      contactNumber: '+1234567891',
    ),
  ];

  /// Mock invite members (not yet in chat)
  static List<ChatMember> get mockInviteMembers => [
    ChatMember(
      id: 'invite1',
      name: 'Emma Johnson',
      email: 'alicesmith@example.com',
      avatar:
          'http://localhost:3845/assets/559116a5c9368d480d16b06ebf3d77a43eb9e234.png',
      role: 'Technician',
      team: 'Support Team',
      isOnline: true,
      isTeamMember: false,
      contactNumber: '+1234567892',
    ),
    ChatMember(
      id: 'invite2',
      name: 'Michael Brown',
      email: 'alicesmith@example.com',
      avatar:
          'http://localhost:3845/assets/a5323b12c9299fb148d4b99d8ca6b3b59e617a3f.png',
      role: 'Supervisor',
      team: 'Operations Team',
      isOnline: false,
      isTeamMember: false,
      contactNumber: '+1234567893',
    ),
    ChatMember(
      id: 'invite3',
      name: 'Ingrid Baum',
      email: 'niamhoconnell@example.com',
      avatar:
          'http://localhost:3845/assets/559116a5c9368d480d16b06ebf3d77a43eb9e234.png',
      role: 'Field Manager',
      team: 'Field Team',
      isOnline: true,
      isTeamMember: false,
      contactNumber: '+1234567894',
    ),
  ];

  /// Get member by ID
  static ChatMember? getMemberById(String id) {
    try {
      return [
        ...mockTeamMembers,
        ...mockInviteMembers,
      ].firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get member details from sender ID in messages
  static ChatMember? getMemberFromMessage(ChatMessage message) {
    if (message.isMe) {
      return ChatMember(
        id: 'currentUser',
        name: 'You',
        email: 'you@example.com',
        avatar: message.senderAvatar,
        role: 'ER Team Lead',
        team: 'ER Team',
        isOnline: true,
        isTeamMember: true,
      );
    }

    // Try to find from existing members
    return getMemberById(message.senderId) ??
        ChatMember(
          id: message.senderId,
          name: message.senderName,
          email:
              '${message.senderName.toLowerCase().replaceAll(' ', '')}@example.com',
          avatar: message.senderAvatar,
          role: 'Team Member',
          team: 'ER Team',
          isOnline: message.isOnline,
          isTeamMember: true,
        );
  }
}
