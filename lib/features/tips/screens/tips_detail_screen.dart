import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/core/constants/colors.dart';

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
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: AppColors.primaryGreen),
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
                  //
                  // Artikel datang dalam format Markdown. Sebelumnya dirender
                  // sebagai teks biasa, sehingga penanda mentahnya ikut
                  // terbaca ("### Solusi Cepat", "**tebal**", "- poin").
                  MarkdownBody(
                    data: content,
                    selectable: true,
                    onTapLink: (text, href, title) => _openLink(href),
                    styleSheet: _articleStyle(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Gaya baca untuk artikel panjang: lebih lapang daripada gelembung chat,
  /// dengan hierarki judul yang jelas supaya mudah dipindai.
  MarkdownStyleSheet _articleStyle(BuildContext context) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
      pPadding: const EdgeInsets.only(bottom: 12),
      h1: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
      h2: const TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
      h3: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen),
      h4: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      h1Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h2Padding: const EdgeInsets.only(top: 18, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 6),
      h4Padding: const EdgeInsets.only(top: 14, bottom: 6),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet:
          const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
      listIndent: 20,
      blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.primaryGreen, width: 3),
        ),
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: Colors.grey.shade200,
        color: Colors.black87,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      a: const TextStyle(
        color: AppColors.primaryGreen,
        decoration: TextDecoration.underline,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}
