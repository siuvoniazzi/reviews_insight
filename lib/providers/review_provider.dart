import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/store_service.dart';
import '../services/gemini_service.dart';

class ReviewProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();

  List<Review> _reviews = [];
  String _insights = '';
  bool _isLoading = false;
  String? _error;

  List<Review> get reviews => _reviews;
  String get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GeminiService? _geminiService;

  void setApiKey(String key) {
    _geminiService = GeminiService(apiKey: key);
  }

  Future<void> analyzeFiles({Uint8List? appleCsv, Uint8List? googleCsv}) async {
    if (_geminiService == null) {
      _error = "Please enter a valid Gemini API Key first.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _reviews = [];
    _insights = '';
    notifyListeners();

    try {
      final List<Review> allReviews = [];

      if (appleCsv != null) {
        allReviews.addAll(_storeService.parseAppleCsv(appleCsv));
      }

      if (googleCsv != null) {
        allReviews.addAll(_storeService.parseGoogleCsv(googleCsv));
      }

      if (allReviews.isEmpty) {
        _error = "No valid reviews found in the uploaded files.";
      } else {
        _reviews = allReviews;
        // Generate insights client-side
        _insights = await _geminiService!.generateInsights(_reviews);
      }
    } catch (e) {
      _error = "Error during analysis: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
