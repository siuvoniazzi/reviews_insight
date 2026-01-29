import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/review.dart';

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<String> generateInsights(List<Review> reviews) async {
    if (reviews.isEmpty) return "No reviews to analyze.";

    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
    );

    final prompt = StringBuffer();
    prompt.writeln(
      "Analyze the following mobile app reviews and provide helpful insights.",
    );
    prompt.writeln(
      "Please provide: 1. A global sentiment summary. 2. Top 3 positive points. 3. Top 3 negative points. 4. Actionable advice for the developers.",
    );
    prompt.writeln("\nReviews:");

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
