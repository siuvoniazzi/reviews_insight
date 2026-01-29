class InsightResult {
  final String sentiment;
  final List<String> topPositive;
  final List<String> topNegative;
  final List<String> advice;
  final String verdict; // "POSITIVE", "NEGATIVE", "NEUTRAL"

  InsightResult({
    required this.sentiment,
    required this.topPositive,
    required this.topNegative,
    required this.advice,
    required this.verdict,
  });

  factory InsightResult.fromJson(Map<String, dynamic> json) {
    return InsightResult(
      sentiment: json['sentiment'] ?? "Keine Zusammenfassung verfügbar.",
      topPositive: List<String>.from(json['top_positive'] ?? []),
      topNegative: List<String>.from(json['top_negative'] ?? []),
      advice: List<String>.from(json['advice'] ?? []),
      verdict: json['verdict'] ?? "NEUTRAL",
    );
  }

  factory InsightResult.empty() {
    return InsightResult(
      sentiment: "",
      topPositive: [],
      topNegative: [],
      advice: [],
      verdict: "NEUTRAL",
    );
  }
}
