import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:petani_maju/widgets/skeleton_container.dart';

class DrugDetailScreen extends StatefulWidget {
  final Map<String, dynamic> drug;
  const DrugDetailScreen({super.key, required this.drug});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  int _selectedTabIndex = 0;
  bool _isSaved = false;

  /// Nama obat — dukung dua bentuk data: 'nama' (katalog) & 'nama_obat' (rekomendasi scanner).
  String get _drugName =>
      _safeString(widget.drug['nama'], fallback: _safeString(widget.drug['nama_obat']));

  /// Link pembelian dari JSON (mis. hyperlink Shopee). Null jika tidak tersedia.
  String? get _purchaseUrl {
    final raw = widget.drug['link_pembelian'];
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _openPurchaseLink() async {
    final url = _purchaseUrl;
    if (url == null) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('Link pembelian tidak valid');
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSnack('Tidak dapat membuka link pembelian');
      }
    } catch (e) {
      _showSnack('Gagal membuka link pembelian');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final isOrganik = drug['organik'] as bool? ?? false;
    final categoryLabel = _safeString(drug['kategori']);
    final imageUrl = _safeString(drug['gambar_url'], fallback: _placeholderImageForCategory(categoryLabel));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      bottomNavigationBar: _purchaseUrl != null ? _buildBuyBar() : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.primaryGreen,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isSaved = !_isSaved;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSaved ? 'Obat disimpan' : 'Obat dihapus dari simpanan'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur berbagi sedang dikembangkan'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[100],
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SkeletonContainer.square(
                        width: double.infinity,
                        height: 300,
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey[400],
                        size: 64,
                      ),
                    ),
                  ),
                  // Organic Badge
                  if (isOrganik)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              'Organik',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha:0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Drug Info Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(categoryLabel).withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(categoryLabel).withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      categoryLabel,
                      style: TextStyle(
                        color: _getCategoryColor(categoryLabel),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Drug Name
                  Text(
                    _drugName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Manufacturer
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _safeString(drug['produsen']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (drug['tanaman'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.grass, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _valueToString(drug['tanaman']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.local_pharmacy_outlined,
                          title: 'Bahan Aktif',
                          value: drug['bahan_aktif'].toString().split(',')[0],
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.format_list_bulleted,
                          title: 'Dosis',
                          value: drug['dosis'].toString().split('per')[0].trim(),
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tab Navigation
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Deskripsi', 0),
                        _buildTabButton('Sasaran', 1),
                        _buildTabButton('Cara Pakai', 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Content
                  _buildTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom bar dengan tombol beli obat (hyperlink ke link_pembelian).
  Widget _buildBuyBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openPurchaseLink,
            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
            label: const Text(
              'Beli Obat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primaryGreen : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.primaryGreen : Colors.grey,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final drug = widget.drug;

    switch (_selectedTabIndex) {
      case 0:
        // Deskripsi
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deskripsi Produk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                _safeString(drug['deskripsi']),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bahan Aktif Lengkap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                _safeString(drug['bahan_aktif']),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        );

      case 1:
        // Sasaran / Target
        final sasaran = drug['sasaran'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sasaran Pengendalian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: sasaran is List
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sasaran.map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.6,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : Row(
                      children: [
                        Icon(Icons.bug_report_outlined, color: Colors.orange.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _valueToString(sasaran),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );

      case 2:
        // Cara Pakai
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dosis & Cara Penggunaan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dosis: ${_safeString(drug['dosis'])}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _safeString(drug['cara_pakai']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ikuti petunjuk penggunaan dengan benar untuk hasil optimal dan keamanan maksimal.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _safeString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _valueToString(dynamic value) {
    if (value == null) return '-';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  String _placeholderImageForCategory(String category) {
    switch (category) {
      case 'Insektisida':
        return 'https://images.unsplash.com/photo-1518655048521-f130df041f66?auto=format&fit=crop&q=80&w=400';
      case 'Fungisida':
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
      case 'Pupuk & Nutrisi':
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
      case 'Organik':
        return 'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&q=80&w=400';
      default:
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
    }
  }

  Color _getCategoryColor(dynamic category) {
    switch (_safeString(category)) {
      case 'Insektisida':
        return Colors.red.shade700;
      case 'Fungisida':
        return Colors.orange.shade700;
      case 'Pupuk & Nutrisi':
        return Colors.blue.shade700;
      case 'Organik':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
