import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/review.dart';

class StoreService {
  /// Parses CSV bytes from Apple App Store Connect
  List<Review> parseAppleCsv(Uint8List fileBytes) {
    try {
      final String content = utf8.decode(fileBytes);
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        content,
        eol: '\n',
      );

      // Apple CSV Header is usually:
      // "App Name","App Apple ID","Store Front","App Version","Rating","Title","Review","Date","Nickname"...
      if (rows.isEmpty) return [];

      final headers = rows[0].map((e) => e.toString().toLowerCase()).toList();
      final ratingIdx = headers.indexOf('rating');
      final reviewIdx = headers.indexOf('review');
      final nickIdx = headers.indexOf('nickname');

      if (ratingIdx == -1 || reviewIdx == -1) {
        throw Exception(
          "Invalid Apple CSV format. Missing 'Rating' or 'Review' columns.",
        );
      }

      final List<Review> reviews = [];
      // Skip header
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length <= reviewIdx) continue;

        final double rating = double.tryParse(row[ratingIdx].toString()) ?? 0.0;
        final String body = row[reviewIdx].toString();
        final String author = nickIdx != -1 && row.length > nickIdx
            ? row[nickIdx].toString()
            : "Anonymous";

        reviews.add(
          Review(
            author: author,
            rating: rating,
            content: body,
            date: DateTime.now(), // Placeholder
            source: ReviewSource.apple,
          ),
        );
      }
      return reviews;
    } catch (e) {
      // print("Error parsing Apple CSV: $e");
      rethrow;
    }
  }

  /// Parses CSV bytes from Google Play Console
  List<Review> parseGoogleCsv(Uint8List fileBytes) {
    try {
      String content;

      // 1. Detect UTF-16LE BOM (0xFF, 0xFE)
      if (fileBytes.length >= 2 &&
          fileBytes[0] == 0xFF &&
          fileBytes[1] == 0xFE) {
        print("Debug: Detected UTF-16LE BOM");
        // Decode UTF-16LE manually
        final buffer = StringBuffer();
        // Start at 2 to skip BOM
        for (int i = 2; i < fileBytes.length; i += 2) {
          if (i + 1 < fileBytes.length) {
            int charCode = fileBytes[i] | (fileBytes[i + 1] << 8);
            buffer.writeCharCode(charCode);
          }
        }
        content = buffer.toString();
      } else {
        // 2. Try UTF-8 first
        try {
          content = utf8.decode(fileBytes);
          print("Debug: Decoded as UTF-8");
        } catch (e) {
          // 3. Fallback to Latin1
          content = latin1.decode(fileBytes);
          print("Debug: Fallback to Latin1");
        }
      }

      // 4. Normalize EOLs: Replace \r\n and \r with \n
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // Auto-detect EOL
      print("Debug: Converting CSV content to list...");
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        content,
        eol: '\n',
      );
      print("Debug: Parsed ${rows.length} rows.");

      if (rows.isEmpty) return [];

      // Clean headers: trim and lowercase
      final headers = rows[0]
          .map((e) => e.toString().trim().toLowerCase())
          .toList();

      print("Debug: Headers: $headers");

      // Robust matching using contains
      final ratingIdx = headers.indexWhere((h) => h.contains('star rating'));
      final textIdx = headers.indexWhere((h) => h.contains('review text'));
      final titleIdx = headers.indexWhere((h) => h.contains('review title'));
      final dateIdx = headers.indexWhere((h) => h.contains('submit date'));

      print(
        "Debug: Indices - Rating: $ratingIdx, Text: $textIdx, Title: $titleIdx, Date: $dateIdx",
      );

      if (ratingIdx == -1) {
        throw Exception(
          "Invalid Google CSV format. Found headers: $headers. Expected validation: 'Star Rating'.",
        );
      }

      final List<Review> reviews = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Safety check for row length
        if (row.length <= ratingIdx) {
          print(
            "Debug: Skipping Row $i (Length ${row.length} <= RatingIdx $ratingIdx). Content: $row",
          );
          continue;
        }

        final double rating = double.tryParse(row[ratingIdx].toString()) ?? 0.0;

        // Build Content: Title + Body
        String body = "";
        if (textIdx != -1 && row.length > textIdx) {
          body = row[textIdx].toString();
        }

        if (titleIdx != -1 && row.length > titleIdx) {
          final String title = row[titleIdx].toString();
          if (title.isNotEmpty) {
            body = body.isEmpty ? title : "$title\n$body";
          }
        }

        if (body.isEmpty) {
          body = "[No written review]";
        }

        DateTime date = DateTime.now();
        if (dateIdx != -1 && row.length > dateIdx) {
          try {
            // Format: 2024-02-01T18:14:50Z
            date = DateTime.parse(row[dateIdx].toString());
          } catch (e) {
            // ignore parse error, use now
            print("Debug: Date parse error row $i: $e");
          }
        }

        reviews.add(
          Review(
            author: "Google User", // Anonymized in this export
            rating: rating,
            content: body,
            date: date,
            source: ReviewSource.google,
          ),
        );
      }

      print("Debug: Extracted ${reviews.length} reviews.");
      return reviews;
    } catch (e) {
      print("Error parsing Google CSV: $e");
      rethrow;
    }
  }
}
