import 'org_member_model.dart';
import 'org_role_model.dart';

/// Static mock data for organization structure
class OrgData {
  // Color codes for different hierarchy levels
  static const String topLevelColor = '#3DA229'; // Green
  static const String midLevelColor = '#E5A800'; // Yellow
  static const String lowLevelColor = '#DE8A02'; // Orange

  /// Mock members data mapped by role ID
  static final Map<String, List<OrgMember>> _membersByRole = {
    'employer-management-director': [
      const OrgMember(
        id: '1',
        name: 'Alice Smith',
        email: 'alicesmith@example.com',
        avatar: 'https://i.pravatar.cc/150?img=1',
        isOnline: true,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '2',
        name: 'John Doe',
        email: 'johndoe@example.com',
        avatar: 'https://i.pravatar.cc/150?img=2',
        isOnline: false,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '3',
        name: 'Emma Johnson',
        email: 'emmajohnson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=3',
        isOnline: true,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '4',
        name: 'Michael Brown',
        email: 'michaelbrown@example.com',
        avatar: 'https://i.pravatar.cc/150?img=4',
        isOnline: true,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '5',
        name: 'Sara Wilson',
        email: 'sarawilson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=5',
        isOnline: false,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '6',
        name: 'David Lee',
        email: 'davidlee@example.com',
        avatar: 'https://i.pravatar.cc/150?img=6',
        isOnline: false,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '7',
        name: 'Laura Miller',
        email: 'lauramiller@example.com',
        avatar: 'https://i.pravatar.cc/150?img=7',
        isOnline: true,
        position: 'Employer Management Director',
      ),
      const OrgMember(
        id: '8',
        name: 'Chris Taylor',
        email: 'christaylor@example.com',
        avatar: 'https://i.pravatar.cc/150?img=8',
        isOnline: true,
        position: 'Employer Management Director',
      ),
    ],
    'crisis-team-lead': [
      const OrgMember(
        id: '9',
        name: 'Sarah Connor',
        email: 'sarah.connor@example.com',
        avatar: 'https://i.pravatar.cc/150?img=9',
        isOnline: true,
        position: 'Crisis Team Lead',
      ),
      const OrgMember(
        id: '10',
        name: 'James Mitchell',
        email: 'james.mitchell@example.com',
        avatar: 'https://i.pravatar.cc/150?img=10',
        isOnline: false,
        position: 'Crisis Team Lead',
      ),
    ],
    'employer-response-coordinator': [
      const OrgMember(
        id: '11',
        name: 'Robert Taylor',
        email: 'robert.taylor@example.com',
        avatar: 'https://i.pravatar.cc/150?img=11',
        isOnline: true,
        position: 'Employer Response Coordinator',
      ),
      const OrgMember(
        id: '12',
        name: 'Jennifer White',
        email: 'jennifer.white@example.com',
        avatar: 'https://i.pravatar.cc/150?img=12',
        isOnline: true,
        position: 'Employer Response Coordinator',
      ),
      const OrgMember(
        id: '13',
        name: 'Mark Johnson',
        email: 'mark.johnson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=13',
        isOnline: false,
        position: 'Employer Response Coordinator',
      ),
    ],
    'she-manager': [
      const OrgMember(
        id: '14',
        name: 'Laura Harris',
        email: 'laura.harris@example.com',
        avatar: 'https://i.pravatar.cc/150?img=14',
        isOnline: true,
        position: 'SHE Manager',
      ),
    ],
    'operations-logistics': [
      const OrgMember(
        id: '15',
        name: 'Thomas Clark',
        email: 'thomas.clark@example.com',
        avatar: 'https://i.pravatar.cc/150?img=15',
        isOnline: true,
        position: 'Operations & Logistics',
      ),
      const OrgMember(
        id: '16',
        name: 'Emily Davis',
        email: 'emily.davis@example.com',
        avatar: 'https://i.pravatar.cc/150?img=16',
        isOnline: false,
        position: 'Operations & Logistics',
      ),
    ],
    'on-site-employer-manager': [
      const OrgMember(
        id: '17',
        name: 'Kevin Martinez',
        email: 'kevin.martinez@example.com',
        avatar: 'https://i.pravatar.cc/150?img=17',
        isOnline: true,
        position: 'On-Site Employer Manager',
      ),
    ],
    'training-coordinator': [
      const OrgMember(
        id: '18',
        name: 'Patricia Anderson',
        email: 'patricia.anderson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=18',
        isOnline: false,
        position: 'Training Coordinator',
      ),
    ],
    'commander-officer': [
      const OrgMember(
        id: '19',
        name: 'Christopher Wilson',
        email: 'christopher.wilson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=19',
        isOnline: true,
        position: 'Commander Officer',
      ),
    ],
    'security-manager': [
      const OrgMember(
        id: '20',
        name: 'Nancy Thompson',
        email: 'nancy.thompson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=20',
        isOnline: true,
        position: 'Security Manager',
      ),
    ],
    'on-scene-commander': [
      const OrgMember(
        id: '21',
        name: 'Daniel Garcia',
        email: 'daniel.garcia@example.com',
        avatar: 'https://i.pravatar.cc/150?img=21',
        isOnline: false,
        position: 'On-Scene Commander',
      ),
    ],
    'fire-rescue-lead': [
      const OrgMember(
        id: '22',
        name: 'Jessica Moore',
        email: 'jessica.moore@example.com',
        avatar: 'https://i.pravatar.cc/150?img=22',
        isOnline: true,
        position: 'Fire & Rescue Lead',
      ),
    ],
    'medical-employer-lead': [
      const OrgMember(
        id: '23',
        name: 'Andrew Wilson',
        email: 'andrew.wilson@example.com',
        avatar: 'https://i.pravatar.cc/150?img=23',
        isOnline: true,
        position: 'Medical Employer Lead',
      ),
    ],
    'field-workers': [
      const OrgMember(
        id: '24',
        name: 'Matthew Rodriguez',
        email: 'matthew.rodriguez@example.com',
        avatar: 'https://i.pravatar.cc/150?img=24',
        isOnline: true,
        position: 'Field Workers',
      ),
    ],
    'maintenance-staff': [
      const OrgMember(
        id: '25',
        name: 'Ashley Lewis',
        email: 'ashley.lewis@example.com',
        avatar: 'https://i.pravatar.cc/150?img=25',
        isOnline: false,
        position: 'Maintenance Staff',
      ),
    ],
  };

  /// Get organization hierarchy structure
  static OrgRole getOrgStructure() {
    // Level 4 roles (bottom level)
    final onSceneCommander = OrgRole(
      id: 'on-scene-commander',
      title: 'On-Scene Commander',
      members: _membersByRole['on-scene-commander'] ?? [],
      children: [],
      level: 4,
      colorCode: lowLevelColor,
    );

    final fireRescueLead = OrgRole(
      id: 'fire-rescue-lead',
      title: 'Fire & Rescue Lead',
      members: _membersByRole['fire-rescue-lead'] ?? [],
      children: [],
      level: 4,
      colorCode: lowLevelColor,
    );

    final medicalEmployerLead = OrgRole(
      id: 'medical-employer-lead',
      title: 'Medical Employer Lead',
      members: _membersByRole['medical-employer-lead'] ?? [],
      children: [],
      level: 4,
      colorCode: lowLevelColor,
    );

    final fieldWorkers = OrgRole(
      id: 'field-workers',
      title: 'Field Workers',
      members: _membersByRole['field-workers'] ?? [],
      children: [],
      level: 4,
      colorCode: lowLevelColor,
    );

    final maintenanceStaff = OrgRole(
      id: 'maintenance-staff',
      title: 'Maintenance Staff',
      members: _membersByRole['maintenance-staff'] ?? [],
      children: [],
      level: 4,
      colorCode: lowLevelColor,
    );

    // Level 3 roles
    final operationsLogistics = OrgRole(
      id: 'operations-logistics',
      title: 'Operations & Logistics',
      members: _membersByRole['operations-logistics'] ?? [],
      children: [onSceneCommander, fireRescueLead, medicalEmployerLead],
      level: 3,
      colorCode: lowLevelColor,
    );

    final onSiteEmployerManager = OrgRole(
      id: 'on-site-employer-manager',
      title: 'On-Site Employer Manager',
      members: _membersByRole['on-site-employer-manager'] ?? [],
      children: [],
      level: 3,
      colorCode: lowLevelColor,
    );

    final trainingCoordinator = OrgRole(
      id: 'training-coordinator',
      title: 'Training Coordinator',
      members: _membersByRole['training-coordinator'] ?? [],
      children: [fieldWorkers],
      level: 3,
      colorCode: lowLevelColor,
    );

    final commanderOfficer = OrgRole(
      id: 'commander-officer',
      title: 'Commander Officer',
      members: _membersByRole['commander-officer'] ?? [],
      children: [maintenanceStaff],
      level: 3,
      colorCode: lowLevelColor,
    );

    final securityManager = OrgRole(
      id: 'security-manager',
      title: 'Security Manager',
      members: _membersByRole['security-manager'] ?? [],
      children: [],
      level: 3,
      colorCode: lowLevelColor,
    );

    // Level 2 roles
    final crisisTeamLead = OrgRole(
      id: 'crisis-team-lead',
      title: 'Crisis Team Lead',
      members: _membersByRole['crisis-team-lead'] ?? [],
      children: [operationsLogistics, onSiteEmployerManager],
      level: 2,
      colorCode: midLevelColor,
    );

    final employerResponseCoordinator = OrgRole(
      id: 'employer-response-coordinator',
      title: 'Employer Response Coordinator',
      members: _membersByRole['employer-response-coordinator'] ?? [],
      children: [trainingCoordinator, commanderOfficer],
      level: 2,
      colorCode: midLevelColor,
    );

    final sheManager = OrgRole(
      id: 'she-manager',
      title: 'SHE Manager',
      members: _membersByRole['she-manager'] ?? [],
      children: [securityManager],
      level: 2,
      colorCode: midLevelColor,
    );

    // Level 1 (top level - root)
    final employerManagementDirector = OrgRole(
      id: 'employer-management-director',
      title: 'Employer Management Director',
      members: _membersByRole['employer-management-director'] ?? [],
      children: [crisisTeamLead, employerResponseCoordinator, sheManager],
      level: 1,
      colorCode: topLevelColor,
    );

    return employerManagementDirector;
  }

  /// Get all members
  static List<OrgMember> getAllMembers() {
    return _membersByRole.values.expand((members) => members).toList();
  }
}
