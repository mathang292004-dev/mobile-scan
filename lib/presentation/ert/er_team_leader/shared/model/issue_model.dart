class Issue {
  final String code;
  final String title;
  final String subtitle;
  final String status; // "Progress" or "Resolved"
  final String severity; // "Low", "Medium", "High"
  final String priority; // "Low", "Medium", "High"

  Issue({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.severity,
    required this.priority,
  });
}

final List<Issue> issues = [
  Issue(
      code: "ISS001",
      title: "Login not working",
      subtitle: "User unable to login with valid credentials",
      status: "Progress",
      severity: "High",
      priority: "Urgent"),
  Issue(
      code: "ISS002",
      title: "App crash on upload",
      subtitle: "Crash when uploading large files",
      status: "Resolved",
      severity: "Medium",
      priority: "High"),
  Issue(
      code: "ISS003",
      title: "UI misalignment",
      subtitle: "Buttons overlap on smaller screens",
      status: "Progress",
      severity: "Low",
      priority: "Medium"),
];
