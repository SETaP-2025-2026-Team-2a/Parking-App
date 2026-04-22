import 'package:flutter/material.dart';

class Review {
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class HistoryTabContent extends StatefulWidget {
  const HistoryTabContent({super.key});

  @override
  State<HistoryTabContent> createState() => _HistoryTabContentState();
}

class _HistoryTabContentState extends State<HistoryTabContent> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 5;
  late ScrollController _scrollController;

  final List<Review> _pastReviews = [
    Review(
      userName: 'Alex Johnson',
      rating: 5,
      comment:
          'Great location! Easy to find and very secure. Highly recommended.',
      date: DateTime(2025, 12, 20),
    ),
    Review(
      userName: 'Sarah Williams',
      rating: 4,
      comment: 'Good spot. A bit tight but affordable. Would park here again.',
      date: DateTime(2025, 12, 15),
    ),
    Review(
      userName: 'Mike Chen',
      rating: 5,
      comment: 'Excellent! Clean, well-lit, and has good security cameras.',
      date: DateTime(2025, 12, 10),
    ),
    Review(
      userName: 'Emma Green',
      rating: 3,
      comment: 'Average parking spot. Gets busy during peak hours.',
      date: DateTime(2025, 12, 5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    setState(() {
      _pastReviews.insert(
        0,
        Review(
          userName: 'You',
          rating: _userRating,
          comment: _commentController.text,
          date: DateTime.now(),
        ),
      );
      _commentController.clear();
      _userRating = 5;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review submitted!')));

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildStars(double rating, {bool interactive = false}) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < rating;
        return interactive
            ? GestureDetector(
              onTap: () => setState(() => _userRating = index + 1.0),
              child: Icon(
                Icons.star,
                color: filled ? Colors.amber : Colors.grey.shade300,
                size: 28,
              ),
            )
            : Icon(
              Icons.star,
              color: filled ? Colors.amber : Colors.grey.shade300,
              size: 18,
            );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Reviews'), centerTitle: true),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Leave a Review Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Your Experience',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rate: ${_userRating.toStringAsFixed(0)} / 5',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildStars(_userRating, interactive: true),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your feedback...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'User Reviews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pastReviews.length,
              itemBuilder: (context, index) {
                final review = _pastReviews[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatDate(review.date),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          _buildStars(review.rating),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review.comment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
