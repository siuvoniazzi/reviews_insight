import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/review_provider.dart';
import '../models/review.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReviewProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights Dashboard')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Insights Panel
                Expanded(
                  flex: 1,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gemini Insights",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Divider(),
                          Expanded(child: Markdown(data: provider.insights)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Reviews List Panel
                Expanded(
                  flex: 1,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Recent Reviews (${provider.reviews.length})",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            itemCount: provider.reviews.length,
                            separatorBuilder: (ctx, i) => const Divider(),
                            itemBuilder: (context, index) {
                              final review = provider.reviews[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRatingColor(
                                    review.rating,
                                  ),
                                  foregroundColor: Colors.white,
                                  child: Text(review.rating.toString()),
                                ),
                                title: Text(review.author),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      review.date.toString().split(' ')[0],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  review.source == ReviewSource.apple
                                      ? Icons.apple
                                      : Icons.android,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.amber;
    return Colors.red;
  }
}
