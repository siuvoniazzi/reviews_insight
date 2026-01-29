import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/review_provider.dart';

import '../services/pdf_service.dart';

class DashboardScreen extends StatelessWidget {
  final String appName;

  const DashboardScreen({super.key, this.appName = "App"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse: $appName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "PDF Bericht herunterladen",
            onPressed: () async {
              final provider = Provider.of<ReviewProvider>(
                context,
                listen: false,
              );
              final pdfService = PdfService();

              await pdfService.generateReport(
                appName: appName,
                appleInsights: provider.appleInsights,
                googleInsights: provider.googleInsights,
                appleReviews: provider.appleReviews,
                googleReviews: provider.googleReviews,
              );
            },
          ),
        ],
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, child) {
          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.appleReviews.isEmpty && provider.googleReviews.isEmpty) {
            return const Center(child: Text("Keine Daten gefunden."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Insights Comparison Section
                Text(
                  "Gemini Insights Comparison",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    final hasApple = provider.appleReviews.isNotEmpty;
                    final hasGoogle = provider.googleReviews.isNotEmpty;

                    if (isWide && hasApple && hasGoogle) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  context,
                                  "Apple App Store Insights ${_getDateRange(provider.appleReviews)}",
                                  Icons.apple,
                                ),
                                const SizedBox(height: 8),
                                _buildInsightBox(
                                  context,
                                  provider.appleInsights,
                                  Colors.grey.shade100,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  context,
                                  "Google Play Store Insights ${_getDateRange(provider.googleReviews)}",
                                  Icons.android,
                                ),
                                const SizedBox(height: 8),
                                _buildInsightBox(
                                  context,
                                  provider.googleInsights,
                                  Colors.green.shade50,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasApple) ...[
                            _buildSectionHeader(
                              context,
                              "Apple App Store Insights ${_getDateRange(provider.appleReviews)}",
                              Icons.apple,
                            ),
                            const SizedBox(height: 8),
                            _buildInsightBox(
                              context,
                              provider.appleInsights,
                              Colors.grey.shade100,
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (hasGoogle) ...[
                            _buildSectionHeader(
                              context,
                              "Google Play Store Insights ${_getDateRange(provider.googleReviews)}",
                              Icons.android,
                            ),
                            const SizedBox(height: 8),
                            _buildInsightBox(
                              context,
                              provider.googleInsights,
                              Colors.green.shade50,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      );
                    }
                  },
                ),

                const Divider(thickness: 2),
                const SizedBox(height: 32),

                // 2. Appendix: All Reviews
                Text(
                  "Appendix: Alle Bewertungen",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                if (provider.appleReviews.isNotEmpty) ...[
                  _buildSectionHeader(context, "Apple Reviews", Icons.apple),
                  const SizedBox(height: 8),
                  _buildReviewList(provider.appleReviews, ReviewSource.apple),
                  const SizedBox(height: 24),
                ],

                if (provider.googleReviews.isNotEmpty) ...[
                  _buildSectionHeader(context, "Google Reviews", Icons.android),
                  const SizedBox(height: 8),
                  _buildReviewList(provider.googleReviews, ReviewSource.google),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  String _getDateRange(List<dynamic> reviews) {
    if (reviews.isEmpty) return "";
    DateTime? minDate;
    DateTime? maxDate;

    for (var review in reviews) {
      if (minDate == null || review.date.isBefore(minDate)) {
        minDate = review.date;
      }
      if (maxDate == null || review.date.isAfter(maxDate)) {
        maxDate = review.date;
      }
    }

    // Should not happen if list is not empty
    if (minDate == null || maxDate == null) return "";

    final minStr = "${minDate.day}.${minDate.month}.${minDate.year}";
    final maxStr = "${maxDate.day}.${maxDate.month}.${maxDate.year}";

    return "($minStr - $maxStr)";
  }

  Widget _buildInsightBox(BuildContext context, String insights, Color color) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Card(
      color: color,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MarkdownBody(data: insights),
      ),
    );
  }

  Widget _buildReviewList(List<dynamic> reviews, ReviewSource source) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getRatingColor(review.rating),
            foregroundColor: Colors.white,
            child: Text(review.rating.toString()),
          ),
          title: Text(review.author),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(review.content),
              const SizedBox(height: 4),
              Text(
                "${review.date.day}.${review.date.month}.${review.date.year}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: Icon(
            source == ReviewSource.apple ? Icons.apple : Icons.android,
            color: Colors.grey,
            size: 16,
          ),
        );
      },
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.amber;
    return Colors.red;
  }
}

enum ReviewSource { apple, google }
