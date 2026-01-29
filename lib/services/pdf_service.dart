import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/review.dart';

class PdfService {
  Future<void> generateReport({
    required String appName,
    required String appleInsights,
    required String googleInsights,
    required List<Review> appleReviews,
    required List<Review> googleReviews,
  }) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final now = DateTime.now();
    final dateStr = "${now.day}.${now.month}.${now.year}";
    final title = "Analyse Bericht: $appName ($dateStr)";

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            if (appleReviews.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text("Apple App Store")),
              pw.Text(
                appleInsights.isNotEmpty
                    ? appleInsights
                    : "Keine Insights verfügbar.",
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Anzahl Bewertungen: ${appleReviews.length}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
            ],

            if (googleReviews.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text("Google Play Store")),
              pw.Text(
                googleInsights.isNotEmpty
                    ? googleInsights
                    : "Keine Insights verfügbar.",
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Anzahl Bewertungen: ${googleReviews.length}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 30),
            ],

            pw.Header(level: 1, child: pw.Text("Detaillierte Bewertungen")),

            if (appleReviews.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10, bottom: 10),
                child: pw.Text(
                  "Apple Bewertungen",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              _buildReviewTable(appleReviews),
              pw.SizedBox(height: 20),
            ],

            if (googleReviews.isNotEmpty) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10, bottom: 10),
                child: pw.Text(
                  "Google Bewertungen",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              _buildReviewTable(googleReviews),
            ],
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'analyse_bericht_${appName.replaceAll(" ", "_")}.pdf',
    );
  }

  pw.Widget _buildReviewTable(List<Review> reviews) {
    return pw.Table.fromTextArray(
      headers: ["Datum", "Bewertung", "Autor", "Inhalt"],
      data: reviews.map((r) {
        return [
          "${r.date.day}.${r.date.month}.${r.date.year}",
          r.rating.toString(),
          r.author,
          r.content,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FixedColumnWidth(35),
        2: const pw.FixedColumnWidth(70),
        3: const pw.FlexColumnWidth(),
      },
    );
  }
}
