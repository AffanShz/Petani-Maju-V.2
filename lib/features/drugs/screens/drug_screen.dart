import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:petani_maju/features/drugs/bloc/drug_bloc.dart';
import 'package:petani_maju/features/drugs/screens/drug_detail_screen.dart';
import 'package:petani_maju/data/repositories/drug_repository.dart';

class DrugScreen extends StatefulWidget {
  const DrugScreen({super.key});

  @override
  State<DrugScreen> createState() => _DrugScreenState();
}

class _DrugScreenState extends State<DrugScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Semua',
    'Fungisida',
    'Bakterisida',
    'Insektisida',
    'Akarisida',
    'Organik',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DrugBloc(
        drugRepository: context.read<DrugRepository>(),
      )..add(LoadDrugs()),
      child: Scaffold(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // Search Bar
                  BlocBuilder<DrugBloc, DrugState>(
                    builder: (context, state) {
                      return TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          // Debounce search
                          Future.delayed(const Duration(milliseconds: 500),
                              () {
                            if (_searchController.text == value &&
                                context.mounted) {
                              context
                                  .read<DrugBloc>()
                                  .add(SearchDrugs(query: value));
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'common.search'.tr(),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF1F3F5),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  BlocBuilder<DrugBloc, DrugState>(
                    builder: (context, state) {
                      final selectedCategory =
                          state is DrugLoaded ? state.selectedCategory : 'Semua';

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _categories
                              .map((category) => _buildCategoryChip(
                                  context, category, selectedCategory))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Medicine List
            Expanded(
              child: BlocBuilder<DrugBloc, DrugState>(
                builder: (context, state) {
                  if (state is DrugLoading || state is DrugInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is DrugError) {
                    return _buildErrorWidget(context, state.message);
                  }

                  if (state is DrugLoaded) {
                    return _buildDrugList(context, state);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugList(BuildContext context, DrugLoaded state) {
    final drugs = state.filteredDrugs;

    if (drugs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded,
                size: 64, color: Colors.grey[400]),
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
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DrugBloc>().add(RefreshDrugs());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: drugs.length,
        itemBuilder: (context, index) {
          return _buildDrugCard(context, drugs[index]);
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
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
                context.read<DrugBloc>().add(LoadDrugs());
              },
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String categoryName, String selectedCategory) {
    final isSelected = selectedCategory == categoryName;
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
          context
              .read<DrugBloc>()
              .add(FilterDrugsByCategory(category: categoryName));
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

  /// Card horizontal (gambar di atas, info di bawah) — full width, scroll vertikal
  Widget _buildDrugCard(BuildContext context, Map<String, dynamic> drug) {
    final category = _safeString(drug['kategori']);
    final imageUrl = _safeString(drug['gambar_url']);
    final name = _safeString(drug['nama']);
    final produsen = _safeString(drug['produsen']);
    final dosis = _safeString(drug['dosis']);

    final sasaranList = _toStringList(drug['sasaran']);
    final tanamanList = _toStringList(drug['tanaman']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => DrugDetailScreen(drug: drug)),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey[400], size: 60),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    produsen,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  if (tanamanList.isNotEmpty)
                    Text(
                      'Tanaman: ${tanamanList.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoPill(Icons.local_pharmacy, dosis,
                          Colors.blue.shade50, Colors.blue.shade700),
                      const SizedBox(width: 8),
                      _buildInfoPill(Icons.bubble_chart, category,
                          Colors.orange.shade50, Colors.orange.shade700),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (sasaranList.isNotEmpty)
                    ...sasaranList.take(3).map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '• $s',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13),
                            ),
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

  Widget _buildInfoPill(
      IconData icon, String label, Color background, Color textColor) {
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

  List<String> _toStringList(dynamic value) {
    final List<String> result = [];
    if (value is List) {
      for (final item in value) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) result.add(text);
      }
    } else if (value != null) {
      final text = value.toString().trim();
      if (text.isNotEmpty) result.add(text);
    }
    return result;
  }

  String _safeString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
