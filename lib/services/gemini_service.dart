import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/review.dart';

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<String> generateInsights(List<Review> reviews) async {
    if (reviews.isEmpty) return "No reviews to analyze.";

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    final prompt = StringBuffer();
    prompt.writeln(
      "Analysiere die folgenden App-Bewertungen und gib hilfreiche Einblicke.",
    );
    prompt.writeln(
      "Bitte gib an: 1. Eine globale Zusammenfassung der Stimmung. 2. Top 3 positive Punkte. 3. Top 3 negative Punkte. 4. Umsetzbare Ratschläge für die Entwickler. Antworte bitte auf Deutsch.",
    );
    prompt.writeln("\nBewertungen:");

    // Efficiency: Take last 50 reviews to fit context window and basic use case
    // In a real app, might want to categorize or sample better.
    for (var review in reviews.take(50)) {
      prompt.writeln(
        "- [${review.source.name}] source: ${review.source.name}, rating: ${review.rating}, content: ${review.content}",
      );
    }

    final content = [Content.text(prompt.toString())];
    try {
      final response = await model.generateContent(content);
      return response.text ?? "No insights generated.";
    } catch (e) {
      return "Error generating insights: $e";
    }
  }
}
