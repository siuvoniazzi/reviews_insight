import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/review.dart';
import '../models/insight_result.dart'; // Import added
import '../services/store_service.dart';
import '../services/gemini_service.dart';

class ReviewProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();

  List<Review> _appleReviews = [];
  List<Review> _googleReviews = [];
  InsightResult _appleInsights = InsightResult.empty(); // Updated type
  InsightResult _googleInsights = InsightResult.empty(); // Updated type

  bool _isLoading = false;
  String? _error;

  List<Review> get appleReviews => _appleReviews;
  List<Review> get googleReviews => _googleReviews;
  InsightResult get appleInsights => _appleInsights; // Updated getter type
  InsightResult get googleInsights => _googleInsights; // Updated getter type

  bool get isLoading => _isLoading;
  String? get error => _error;

  GeminiService? _geminiService;

  void setApiKey(String key) {
    _geminiService = GeminiService(apiKey: key);
  }

  void clearReviews() {
    _appleReviews = [];
    _googleReviews = [];
    _appleInsights = InsightResult.empty();
    _googleInsights = InsightResult.empty();
    _error = null;
    notifyListeners();
  }

  Future<void> setGoogleReviewsFromBytes(List<Uint8List> csvBytesList) async {
    _googleReviews = [];
    for (final fileBytes in csvBytesList) {
      _googleReviews.addAll(_storeService.parseGoogleCsv(fileBytes));
    }
    notifyListeners();
  }

  Future<void> fetchAppleReviews(String appId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _appleReviews = await _storeService.fetchAppleReviews(appId);
    } catch (e) {
      _error = "Error fetching Apple reviews: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyze() async {
    if (_geminiService == null) {
      _error = "Please enter a valid Gemini API Key first.";
      notifyListeners();
      return;
    }

    if (_appleReviews.isEmpty && _googleReviews.isEmpty) {
      _error = "No reviews to analyze. Please fetch or upload reviews first.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_appleReviews.isNotEmpty) {
        _appleReviews.sort((a, b) => b.date.compareTo(a.date));
        _appleInsights = await _geminiService!.generateInsights(_appleReviews);
      }

      if (_googleReviews.isNotEmpty) {
        _googleReviews.sort((a, b) => b.date.compareTo(a.date));
        _googleInsights = await _geminiService!.generateInsights(
          _googleReviews,
        );
      }
    } catch (e) {
      _error = "Error during analysis: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
