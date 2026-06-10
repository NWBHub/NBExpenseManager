class PdfService {
  const PdfService();

  Future<List<int>> fetchMonthlyReportPdf({
    required String token,
    String? month,
  }) async {
    // PDF export endpoint is not implemented in the current backend.
    // Return an empty payload for now so analysis/build stays clean.
    return <int>[];
  }
}
