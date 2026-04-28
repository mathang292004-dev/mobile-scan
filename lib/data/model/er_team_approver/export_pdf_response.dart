/// Response model for PDF export API
class ExportPdfResponse {
  final String pdfUrl;

  ExportPdfResponse({
    required this.pdfUrl,
  });

  factory ExportPdfResponse.fromJson(Map<String, dynamic> json) {
    return ExportPdfResponse(
      pdfUrl: json['pdfUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdfUrl': pdfUrl,
    };
  }
}
