import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

class TipsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tipData;

  const TipsDetailScreen({super.key, required this.tipData});

  @override
  Widget build(BuildContext context) {
    final String title = tipData['title'] ?? 'common.untitled'.tr();
    final String category = tipData['category'] ?? 'Umum';
    final String imageUrl = tipData['image_url'] ?? '';
    final String content =
        tipData['content'] ?? 'tips.content_unavailable'.tr();

    return Scaffold(
      appBar: AppBar(
        title: Text('tips.detail_title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
