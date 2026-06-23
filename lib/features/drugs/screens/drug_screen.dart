import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/features/drugs/screens/drug_detail_screen.dart';

enum DrugCardLayout { vertical, horizontal }

class DrugScreen extends StatefulWidget {
  const DrugScreen({super.key});

  @override
  State<DrugScreen> createState() => _DrugScreenState();
}

class _DrugScreenState extends State<DrugScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "Semua";
  DrugCardLayout _layoutMode = DrugCardLayout.vertical;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> _allDrugs = [];

  @override
  void initState() {
    super.initState();
    _loadDrugData();
  }

  Future<void> _loadDrugData() async {
    try {
      final jsonString = await rootBundle.loadString('katalog_obat_tanaman.json');
      final data = jsonDecode(jsonString) as List<dynamic>;
      _allDrugs = data.map((item) {
        final drug = Map<String, dynamic>.from(item as Map<String, dynamic>);
        drug['nama'] = drug['nama'] ?? drug['nama_obat'] ?? '';
        drug['kategori'] = drug['kategori'] ?? '-';
        drug['produsen'] = drug['produsen'] ?? '-';
        drug['bahan_aktif'] = drug['bahan_aktif'] ?? '-';
        drug['dosis'] = drug['dosis'] ?? '-';
        drug['deskripsi'] = drug['deskripsi'] ?? '-';
        drug['cara_pakai'] = drug['cara_pakai'] ?? '-';
        drug['sasaran'] = drug['sasaran'] ?? [];
        drug['tanaman'] = drug['tanaman'] ?? [];
        drug['organik'] = drug['kategori'] == 'Organik';
        drug['gambar_url'] = _safeString(drug['gambar_url'], fallback: _placeholderImageForCategory(drug['kategori']));
        return drug;
      }).toList();
      _hasError = false;
      _errorMessage = '';
    } catch (e) {
      _allDrugs = [];
      _hasError = true;
      _errorMessage = 'Gagal memuat data obat tanaman. Pastikan file katalog_obat_tanaman.json tersedia dan format JSON benar.';
      debugPrint('Drug data load error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDrugs {
    final query = _searchQuery.toLowerCase();
    return _allDrugs.where((drug) {
      final name = drug['nama']?.toString().toLowerCase() ?? '';
      final bahan = drug['bahan_aktif']?.toString().toLowerCase() ?? '';
      final sasaran = drug['sasaran'] is List
          ? (drug['sasaran'] as List).join(' ').toLowerCase()
          : drug['sasaran']?.toString().toLowerCase() ?? '';
      final produsen = drug['produsen']?.toString().toLowerCase() ?? '';
      final tanaman = drug['tanaman'] is List
          ? (drug['tanaman'] as List).join(' ').toLowerCase()
          : drug['tanaman']?.toString().toLowerCase() ?? '';

      final nameMatches = query.isEmpty ||
          name.contains(query) ||
          bahan.contains(query) ||
          sasaran.contains(query) ||
          produsen.contains(query) ||
          tanaman.contains(query);

      final categoryMatches = _selectedCategory == "Semua" || drug['kategori'] == _selectedCategory;

      return nameMatches && categoryMatches;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'home.menu_drugs'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'common.search'.tr(),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F3F5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildCategoryChip("Semua"),
                      _buildCategoryChip("Fungisida"),
                      _buildCategoryChip("Bakterisida"),
                      _buildCategoryChip("Insektisida"),
                      _buildCategoryChip("Akarisida"),
                      _buildCategoryChip("Organik"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildLayoutToggle(),
              ],
            ),
          ),

          // Medicine List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _hasError = false;
                                    _errorMessage = '';
                                  });
                                  _loadDrugData();
                                },
                                child: Text('common.retry'.tr()),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredDrugs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'common.no_data'.tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _layoutMode == DrugCardLayout.vertical
                            ? ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _filteredDrugs.length,
                                itemBuilder: (context, index) {
                                  final drug = _filteredDrugs[index];
                                  return _buildDrugCard(drug, layout: DrugCardLayout.vertical);
                                },
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(12.0),
                                physics: const BouncingScrollPhysics(),
                                child: LayoutBuilder(builder: (context, constraints) {
                                  // responsive wrap: cards flow down and wrap to next row
                                  final cardWidth = 320.0;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _filteredDrugs.map((drug) {
                                      return SizedBox(
                                        width: cardWidth,
                                        child: _buildDrugCard(drug, layout: DrugCardLayout.horizontal),
                                      );
                                    }).toList(),
                                  );
                                }),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryName) {
    final isSelected = _selectedCategory == categoryName;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          categoryName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryName;
          });
        },
        selectedColor: const Color(0xff1B5E20),
        checkmarkColor: Colors.white,
        backgroundColor: const Color(0xFFF1F3F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildLayoutChip(DrugCardLayout.vertical, Icons.view_agenda, 'Vertikal'),
        const SizedBox(width: 8),
        _buildLayoutChip(DrugCardLayout.horizontal, Icons.view_carousel, 'Horizontal'),
      ],
    );
  }

  Widget _buildLayoutChip(DrugCardLayout mode, IconData icon, String label) {
    final selected = _layoutMode == mode;
    return ChoiceChip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[800]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      selectedColor: const Color(0xff1B5E20),
      backgroundColor: const Color(0xFFF1F3F5),
      onSelected: (_) {
        setState(() {
          _layoutMode = mode;
        });
      },
    );
  }

  String _placeholderImageForCategory(String category) {
    switch (category) {
      case 'Insektisida':
        return 'https://images.unsplash.com/photo-1518655048521-f130df041f66?auto=format&fit=crop&q=80&w=400';
      case 'Fungisida':
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
      case 'Bakterisida':
        return 'https://images.unsplash.com/photo-1556228720-1fae7f6a9b6b?auto=format&fit=crop&q=80&w=400';
      case 'Akarisida':
        return 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=400';
      case 'Organik':
        return 'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&q=80&w=400';
      default:
        return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&q=80&w=400';
    }
  }

  Widget _buildDrugCard(Map<String, dynamic> drug, {required DrugCardLayout layout}) {
    final isOrganik = drug['organik'] as bool? ?? false;
    final category = _safeString(drug['kategori']);
    final imageUrl = _safeString(drug['gambar_url'], fallback: _placeholderImageForCategory(category));
    final name = _safeString(drug['nama']);
    final produsen = _safeString(drug['produsen']);
    final dosis = _safeString(drug['dosis']);

    final sasaranRaw = drug['sasaran'];
    final List<String> sasaranList = [];
    if (sasaranRaw is List) {
      for (final s in sasaranRaw) {
        final t = s?.toString().trim() ?? '';
        if (t.isNotEmpty) sasaranList.add(t);
      }
    } else if (sasaranRaw != null) {
      final t = sasaranRaw.toString().trim();
      if (t.isNotEmpty) sasaranList.add(t);
    }

    // tanaman (plants) list from JSON
    final tanamanRaw = drug['tanaman'];
    final List<String> tanamanList = [];
    if (tanamanRaw is List) {
      for (final t in tanamanRaw) {
        final x = t?.toString().trim() ?? '';
        if (x.isNotEmpty) tanamanList.add(x);
      }
    } else if (tanamanRaw != null) {
      final x = tanamanRaw.toString().trim();
      if (x.isNotEmpty) tanamanList.add(x);
    }

    // Horizontal (grid) layout: card with image top
    if (layout == DrugCardLayout.horizontal) {
      final card = Container(
        width: 280,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 60),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(produsen, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 6),
                  if (tanamanList.isNotEmpty)
                    Text('Tanaman: ${tanamanList.join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _buildInfoPill(Icons.local_pharmacy, dosis, Colors.blue.shade50, Colors.blue.shade700),
                    const SizedBox(width: 8),
                    _buildInfoPill(Icons.bubble_chart, category, Colors.orange.shade50, Colors.orange.shade700),
                  ]),
                  const SizedBox(height: 8),
                  if (sasaranList.isNotEmpty) ...[
                    for (final s in sasaranList.take(3))
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('• $s', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DrugDetailScreen(drug: drug))),
        child: card,
      );
    }

    // Vertical (list) layout: small thumbnail at left, divider, and text to the right
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(width: 56, height: 56, color: Colors.grey.shade200, child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 28));
        },
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DrugDetailScreen(drug: drug))),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          thumbnail,
          const SizedBox(width: 12),
          Container(width: 1, height: 56, color: Colors.grey.shade200),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
                  Text(produsen, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (tanamanList.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text('Tanaman: ${tanamanList.join(', ')}', style: TextStyle(color: Colors.grey[700], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 4),
                  if (sasaranList.isNotEmpty)
                    ...sasaranList.take(4).map((s) => Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text('• $s', style: TextStyle(color: Colors.grey[700], fontSize: 13)))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String label, Color background, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
