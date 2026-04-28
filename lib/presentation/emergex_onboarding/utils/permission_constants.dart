/// Features that only allow Full Access permission
/// All other permissions (Create, View, Edit, Delete) are disabled for these features
const List<String> fullAccessOnlyFeatures = [
  "Upload or Reupload files",
  "Upload or Re-upload Files",
  "Upload file (img, pdf, etc)",
  "Upload File (img/pdf/etc)",
  "Switch Categories (Intervention, Observation, Incident, Near Miss)",
  "Switch Categories",
  "Approval of Incident",
  "View Org Structure",
  "Status of Report & Report Download",
  "ER Team Communication",
];

/// Check if a feature is full access only
bool isFullAccessOnlyFeature(String featureName) {
  return fullAccessOnlyFeatures.any(
    (feature) => feature.toLowerCase() == featureName.toLowerCase(),
  );
}
