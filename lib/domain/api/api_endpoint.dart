class ApiEndpoints {
  static const String baseUrl = 'https://dev-emergex.zapptor.com/api';

  static const String createIncident = '/incident/createIncident';
  static const String updateIncident = '/incident/updateIncident';
  static const String updateReport = '/incident/updateReport';
  static const String incidentUpload = '/incident/upload';
  static const String deleteFileFromServer = '/incident/deleteInformation';
  static const String reportIncident = '/incident/reportIncident';
  static const String deleteIncident = '/incident/deleteIncident/{id}';
  static const String preSignedUrl = '/incident/preSignedUrl';

  static const String updateReportFields = '/incident/updateReportFields';
  static const String updateMembers = '/incident/updateReportFields';
  static const String incidentApproval = '/incident/approval/';
  static const String submitSetup = '/incident/submit-setup';
  // Dashboard endpoints

  static const String getIncidents = '/incident/getIncidents';
  static const String getIncidentsList =
      '/incident/member-dashboard'; // Fixed capitalization
  static const String tlDashboard = '/incident/tl-dashboard';
  static const String myTaskDashboard = '/incident/my-tasks';
  static const String erTeamMemberDashboard = '/incident/er-team-member';
  static const String getIncidentById = '/incident/getIncidentById/{id}';
  static const String removeMemberTask = '/incident/removeMemberTask';
  static const String fetchTeamMembers = '/onboarding/view-details';
  static const String reassignMember = '/incident/reassignMember';
  static const String addMember = '/incident/addMember';
  static const String reassignEligibleUsers = '/incident/reassign-eligible-users';
  static const String addTaskToMember = '/incident/add-task-to-member';
  static const String viewMemberTasks =
      '/incident/view-member-tasks/{incidentId}';

  // Client endpoints
  static const String getClients = '/onboarding/clients';
  static const String addClient = '/onboarding/add-client';
  static const String updateClient = '/onboarding/update-client';
  static const String deleteClient = '/onboarding/delete-client/{clientId}';

  // Project endpoints
  static const String getProjects = '/onboarding/projects';
  static const String addProject = '/onboarding/add-project';
  static const String updateProject = '/onboarding/update-project';
  static const String deleteProject = '/onboarding/delete-project/{projectId}';

  // Chat Room endpoints
  static const String createChatGroup = '/chat-room/create-chat-group';
  static const String getChatMessages = '/chat-room/get-chat-message';
  static const String addChatMember = '/chat-room/add-member';
  static const String removeChatMember = '/chat-room/remove-member';
  static const String getIncidentUsers =
      '/chat-room/incident/{incidentId}/users';

  // Upload Document endpoints
  static const String uploadDoc = '/onboarding/upload-doc';
  static const String uploadDocs = '/onboarding/upload-docs';
  static const String incidentFileUpload = '/incident/file-upload';
  static const String completeOnboarding = '/onboarding/complete-onboarding';
  static const String viewRoleDetails =
      '/onboarding/view-role-details/{roleId}';
  static const String fetchMembers = '/onboarding/fetch-members/{projectId}';
  static const String deleteAssignedUser = '/onboarding/delete-assigned-user';
  static const String viewDetails = '/onboarding/view-details';
  static const String createRole = '/onboarding/create-role';
  static const String deleteRole = '/onboarding/delete-role';
  static const String viewModulesPermissions =
      '/onboarding/view-modules-permissions';
  static const String approverDashboard = '/incident/approver-dashboard';
  static const String closureDashboard = '/incident/closure-dashboard?';
  static const String incidentTasks = '/onboarding/incident-tasks/{incidentId}';

  // My Task endpoint
  static const String myTask = '/onboarding/my-task';
  static const String updateMyTask = '/incident/my-tasks';
  static const String verifyTask = '/onboarding/verify-task';

  // Organization Structure endpoint
  static const String getOrgStructure = '/onboarding/org-structure/{projectId}';

  //login
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refreshToken';
  static const String me = '/auth/me';
  static const String getPermissions = '/auth/getpermissions';

  // User management
  static const String addUser = '/auth/add-user';
  static const String getUsers = '/auth/users';
  static String deleteUser(String userId) => '/auth/users/$userId';
  static const String validateCsvUsers = '/auth/validate-csv-users';
  static const String addBulkUsers = '/auth/add-bulk-users';

  // Password reset (pre-auth — no Authorization header needed)
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String updatePassword = '/auth/update-password';
  static const String resetPassword = '/auth/reset-password';

  // Notification endpoints
  static const String getNotifications = '/notifications';
  static const String getUnreadCount = '/notifications/count';
  static const String markNotificationsAsRead = '/notifications/mark-read';
  static const String registerFCMToken = '/notifications/register-fcm-token';
  static const String unregisterFCMToken =
      '/notifications/unregister-fcm-token';

  // PDF Export endpoints
  static const String exportIncidentPdf = '/incident/pdf-export/{incidentId}';

  // Audit Log endpoints
  static const String getAuditLogs = '/incident/audit-logs/{incidentId}';

  // Preliminary Report
  static const String getPreliminaryReport = '/incident/{incidentId}/preliminary-report';
  static const String updatePreliminaryReport = '/incident/{incidentId}/preliminary-report';
  static const String exportPreliminaryReportPdf = '/incident/{incidentId}/preliminary-report/pdf-export';
}

enum HttpMethod { get, post, put, patch, delete }
