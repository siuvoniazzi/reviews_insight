enum ReviewSource {
  apple,
  google,
}

class Review {
  final String author;
  final double rating;
  final String content;
  final DateTime date;
  final ReviewSource source;

  Review({
    required this.author,
    required this.rating,
    required this.content,
    required this.date,
    required this.source,
  });

  factory Review.fromAppleJson(Map<String, dynamic> json) {
    // Apple RSS feed structure parsing
    final author = json['author']?['name']?['label'] ?? 'Anonymous';
    final content = json['content']?['label'] ?? '';
    final ratingStr = json['im:rating']?['label'] ?? '0';
    final rating = double.tryParse(ratingStr) ?? 0.0;
    
    // Parse date if available, otherwise now
    // Expected format handling or default
    return Review(
      author: author,
      rating: rating,
      content: content,
      date: DateTime.now(), // Apple RSS doesn't always strictly give simple date, need to check format.
      source: ReviewSource.apple,
    );
  }

  @override
  String toString() {
    return 'Review(author: $author, rating: $rating, source: $source, content: $content)';
  }
}
