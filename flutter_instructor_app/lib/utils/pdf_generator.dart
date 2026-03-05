import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/poll_models.dart' as app_models;

class PdfGenerator {
  static pw.Font? _baseFont;
  static pw.Font? _boldFont;
  static pw.Font? _emojiFont;

  static Future<void> _loadFonts() async {
    _baseFont ??= await PdfGoogleFonts.robotoRegular();
    _boldFont ??= await PdfGoogleFonts.robotoBold();
    _emojiFont ??= await PdfGoogleFonts.notoColorEmoji();
  }

  static Future<Uint8List> generatePollResultsPdf(app_models.Poll poll, Map<int, Map<String, dynamic>> tallies) async {
    await _loadFonts();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: _baseFont,
            bold: _boldFont,
            fontFallback: [_emojiFont!],
          ),
        ),
        build: (pw.Context context) {
          final items = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text('Poll Results Summary: ${poll.title}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Date: ${poll.created_at.toLocal().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
          ];

          for (var i = 0; i < poll.questions.length; i++) {
            final question = poll.questions[i];
            final resultData = tallies[question.id];

            items.add(
              pw.Text('Question ${i + 1}: ${question.text}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            );
            items.add(pw.SizedBox(height: 10));

            if (resultData == null || resultData['results'] == null) {
              items.add(pw.Text('No votes yet.'));
              items.add(pw.SizedBox(height: 20));
              continue;
            }

            final results = resultData['results'];

            if (question.type == app_models.QuestionType.open_ended) {
              final responses = (results as List<dynamic>?) ?? [];
              if (responses.isEmpty) {
                items.add(pw.Text('No responses yet.'));
              } else {
                // Responses are chronologically ordered from the DB by default (oldest to newest)
                for (final r in responses) {
                  items.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
                      child: pw.Text('• $r'),
                    ),
                  );
                }
              }
            } else {
              // Multiple Choice or Rating
              final countsMap = (results as Map<String, dynamic>?) ?? {};
              
              if (countsMap.isEmpty) {
                items.add(pw.Text('No votes yet.'));
              } else {
                // Calculate total votes
                int totalVotes = 0;
                countsMap.forEach((key, value) {
                  totalVotes += (value as int);
                });

                if (totalVotes == 0) {
                  items.add(pw.Text('No votes yet.'));
                } else {
                  // Sort by highest vote count
                  final sortedEntries = countsMap.entries.toList()
                    ..sort((a, b) => (b.value as int).compareTo(a.value as int));

                  for (final entry in sortedEntries) {
                    final key = entry.key;
                    final count = entry.value as int;
                    final percentage = count / totalVotes;

                    items.add(
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(key),
                            pw.Text('$count votes (${(percentage * 100).toStringAsFixed(1)}%)'),
                          ],
                        ),
                      ),
                    );
                  }
                  items.add(pw.SizedBox(height: 8));
                  items.add(pw.Text('Total Votes: $totalVotes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
                }
              }
            }
            
            items.add(pw.SizedBox(height: 20));
          }

          return items;
        },
      ),
    );

    return pdf.save();
  }
}

