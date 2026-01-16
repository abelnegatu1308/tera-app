import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../models/trip_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndShareReport(List<TripModel> trips) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(now);

    // Calculate stats
    final totalTrips = trips.length;
    final completedTrips = trips.where((t) => t.status == 'completed').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Tera App - Admin Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Weekly Activity Performance'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Report Date: $dateStr'),
                    pw.Text('Status: Final'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Summary Stats
            pw.Text(
              'Summary Statistics',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Total Trips', totalTrips.toString()),
                _buildStatBox('Completed', completedTrips.toString()),
                _buildStatBox('Avg Daily', (totalTrips / 7).toStringAsFixed(1)),
              ],
            ),
            pw.SizedBox(height: 32),

            // Detailed Table
            pw.Text(
              'Recent Activity Log',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Time', 'Trip ID', 'Status'],
              data: trips.take(50).map((trip) {
                return [
                  DateFormat('yyyy-MM-dd').format(trip.completedAt),
                  DateFormat('hh:mm a').format(trip.completedAt),
                  trip.id.substring(0, 8),
                  trip.status.toUpperCase(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Showing latest ${trips.length > 50 ? 50 : trips.length} records.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Tera_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      width: 150,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
