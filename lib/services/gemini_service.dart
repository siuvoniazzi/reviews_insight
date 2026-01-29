import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/review.dart';
import '../models/insight_result.dart';

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<InsightResult> generateInsights(List<Review> reviews) async {
    if (reviews.isEmpty) return InsightResult.empty();

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt = StringBuffer();
    prompt.writeln(
      "Analysiere die folgenden App-Bewertungen und gib das Ergebnis NUR als valides JSON zurück.",
    );
    prompt.writeln("""
      Erwartetes JSON-Format:
      {
        "sentiment": "Zusammenfassung der Stimmung (max 2 Sätze)",
        "top_positive": ["Punkt 1", "Punkt 2", "Punkt 3"],
        "top_negative": ["Punkt 1", "Punkt 2", "Punkt 3"],
        "advice": ["Rat 1", "Rat 2", "Rat 3"],
        "verdict": "POSITIVE" oder "NEGATIVE" oder "NEUTRAL"
      }
      """);
    prompt.writeln("\nBewertungen:");

    // Efficiency: Take last 50 reviews to fit context window and basic use case
    for (var review in reviews.take(50)) {
      prompt.writeln(
        "- [${review.source.name}] rating: ${review.rating}, content: ${review.content}",
      );
    }

    final content = [Content.text(prompt.toString())];
    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) return InsightResult.empty();

      // Simple parsing, assuming valid JSON execution from Gemini
      // logic to strip markdown code blocks if present
      String jsonString = text.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
      }

      return InsightResult.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print("Error generating insights: $e");
      return InsightResult(
        sentiment: "Fehler: $e",
        topPositive: [],
        topNegative: [],
        advice: [],
        verdict: "NEUTRAL",
      );
    }
  }
}
