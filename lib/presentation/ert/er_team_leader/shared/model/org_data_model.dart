import 'package:emergex/presentation/organization_structure/model/org_member_model.dart';
import 'package:emergex/presentation/organization_structure/model/org_role_model.dart';

/// Static mock data for organization structure
class OrgData {
  // Color codes for different hierarchy levels
  static const String topLevelColor = '#3DA229'; // Green
  static const String midLevelColor = '#E5A800'; // Yellow
  static const String lowLevelColor = '#DE8A02'; // Orange

  /// Mock members data
  static final List<OrgMember> _allMembers = [
    const OrgMember(
      id: '1',
      name: 'John Smith',
      email: 'john.smith@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Chief Executive Officer',
    ),
    const OrgMember(
      id: '2',
      name: 'Sarah Johnson',
      email: 'sarah.j@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Operations Manager',
    ),
    const OrgMember(
      id: '3',
      name: 'Michael Brown',
      email: 'michael.b@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: false,
      position: 'Finance Manager',
    ),
    const OrgMember(
      id: '4',
      name: 'Emily Davis',
      email: 'emily.d@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Team Lead - Operations',
    ),
    const OrgMember(
      id: '5',
      name: 'David Wilson',
      email: 'david.w@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Team Lead - Sales',
    ),
    const OrgMember(
      id: '6',
      name: 'Lisa Anderson',
      email: 'lisa.a@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: false,
      position: 'Accountant',
    ),
    const OrgMember(
      id: '7',
      name: 'Robert Taylor',
      email: 'robert.t@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Financial Analyst',
    ),
    const OrgMember(
      id: '8',
      name: 'Jennifer Martinez',
      email: 'jennifer.m@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Operations Coordinator',
    ),
    const OrgMember(
      id: '9',
      name: 'William Garcia',
      email: 'william.g@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: false,
      position: 'Logistics Specialist',
    ),
    const OrgMember(
      id: '10',
      name: 'Jessica Rodriguez',
      email: 'jessica.r@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Sales Executive',
    ),
    const OrgMember(
      id: '11',
      name: 'Christopher Lee',
      email: 'christopher.l@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'HR Manager',
    ),
    const OrgMember(
      id: '12',
      name: 'Amanda White',
      email: 'amanda.w@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: false,
      position: 'Recruitment Specialist',
    ),
    const OrgMember(
      id: '13',
      name: 'James Harris',
      email: 'james.h@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Training Coordinator',
    ),
    const OrgMember(
      id: '14',
      name: 'Patricia Clark',
      email: 'patricia.c@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'IT Manager',
    ),
    const OrgMember(
      id: '15',
      name: 'Daniel Lewis',
      email: 'daniel.l@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Software Developer',
    ),
    const OrgMember(
      id: '16',
      name: 'Michelle Walker',
      email: 'michelle.w@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: false,
      position: 'System Administrator',
    ),
    const OrgMember(
      id: '17',
      name: 'Matthew Hall',
      email: 'matthew.h@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Quality Assurance Lead',
    ),
    const OrgMember(
      id: '18',
      name: 'Nicole Allen',
      email: 'nicole.a@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'QA Tester',
    ),
    const OrgMember(
      id: '19',
      name: 'Kevin Young',
      email: 'kevin.y@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: false,
      position: 'Marketing Manager',
    ),
    const OrgMember(
      id: '20',
      name: 'Stephanie King',
      email: 'stephanie.k@emergex.com',
      avatar:
          'http://localhost:3845/assets/df808745d4eeae509bbfb902288411fb819999c2.png',
      isOnline: true,
      position: 'Digital Marketing Specialist',
    ),
  ];

  /// Get organization hierarchy structure
  static OrgRole getOrgStructure() {
    // Level 3 roles (grandchildren)
    final qaTeam = OrgRole(
      id: 'role_10',
      title: 'QA Team',
      members: [_allMembers[16], _allMembers[17]],
      children: [],
      level: 3,
      colorCode: lowLevelColor,
    );

    final devTeam = OrgRole(
      id: 'role_11',
      title: 'Development Team',
      members: [_allMembers[14], _allMembers[15]],
      children: [],
      level: 3,
      colorCode: lowLevelColor,
    );

    final marketingTeam = OrgRole(
      id: 'role_12',
      title: 'Marketing Team',
      members: [_allMembers[19]],
      children: [],
      level: 3,
      colorCode: lowLevelColor,
    );

    final hrTeam = OrgRole(
      id: 'role_13',
      title: 'HR Team',
      members: [_allMembers[11], _allMembers[12]],
      children: [],
      level: 3,
      colorCode: lowLevelColor,
    );

    // Level 2 roles (children of Managers)
    final operationsTeamLead = OrgRole(
      id: 'role_4',
      title: 'Operations Team',
      members: [_allMembers[3], _allMembers[7], _allMembers[8]],
      children: [],
      level: 2,
      colorCode: lowLevelColor,
    );

    final financeTeamLead = OrgRole(
      id: 'role_5',
      title: 'Accounting Team',
      members: [_allMembers[5], _allMembers[6]],
      children: [],
      level: 2,
      colorCode: lowLevelColor,
    );

    final salesTeamLead = OrgRole(
      id: 'role_7',
      title: 'Sales Team',
      members: [_allMembers[9]],
      children: [],
      level: 2,
      colorCode: lowLevelColor,
    );

    // Level 1 roles
    final operationsManager = OrgRole(
      id: 'role_2',
      title: 'Operations Manager',
      members: [_allMembers[1]],
      children: [operationsTeamLead],
      level: 1,
      colorCode: midLevelColor,
    );

    final financeManager = OrgRole(
      id: 'role_3',
      title: 'Finance Manager',
      members: [_allMembers[2]],
      children: [financeTeamLead],
      level: 1,
      colorCode: midLevelColor,
    );

    final salesManager = OrgRole(
      id: 'role_6',
      title: 'Sales Manager',
      members: [_allMembers[4]],
      children: [salesTeamLead],
      level: 1,
      colorCode: midLevelColor,
    );

    final hrManager = OrgRole(
      id: 'role_8',
      title: 'HR Manager',
      members: [_allMembers[10]],
      children: [hrTeam],
      level: 1,
      colorCode: midLevelColor,
    );

    final itManager = OrgRole(
      id: 'role_9',
      title: 'IT Manager',
      members: [_allMembers[13]],
      children: [devTeam, qaTeam],
      level: 1,
      colorCode: midLevelColor,
    );

    final marketingManager = OrgRole(
      id: 'role_14',
      title: 'Marketing Manager',
      members: [_allMembers[18]],
      children: [marketingTeam],
      level: 1,
      colorCode: midLevelColor,
    );

    // Level 0 (top level)
    final ceo = OrgRole(
      id: 'role_1',
      title: 'CEO',
      members: [_allMembers[0]],
      children: [
        operationsManager,
        financeManager,
        salesManager,
        hrManager,
        itManager,
        marketingManager,
      ],
      level: 0,
      colorCode: topLevelColor,
    );

    return ceo;
  }

  /// Get all members
  static List<OrgMember> getAllMembers() => _allMembers;
}
