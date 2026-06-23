import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';
import '../../history/screens/history_screen.dart';
import '../../history/bloc/history_bloc.dart';
import '../../history/bloc/history_event.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../data/datasources/pest_services.dart';
import '../../../core/services/cache_service.dart';

// Available plant types
const List<String> _plantTypes = [
  'Tomat',
  'Kentang',
  'Jagung',
  'Cabai',
  'Bayam',
  'Kangkung',
  'Terong',
  'Padi',
];

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScannerBloc(),
      child: const ScannerView(),
    );
  }
}

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => HistoryBloc(
            historyRepository: HistoryRepository(
              pestService: PestService(),
              cacheService: CacheService(),
            ),
          )..add(LoadHistory()),
          child: const HistoryScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text(
          'Deteksi Penyakit Tanaman',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openHistory(context),
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Riwayat Deteksi',
          ),
        ],
      ),
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state is ScannerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ScannerInitial) {
            return _buildInitialView(context, state.selectedPlantType);
          }

          if (state is ScannerLoading) {
            return _buildLoadingView(state.message);
          }

          if (state is ScannerImagePicked) {
            return _buildLoadingView('Menyiapkan gambar...');
          }

          if (state is ScannerSuccess) {
            return _buildResultView(context, state);
          }

          return _buildInitialView(context, 'Tomat');
        },
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView(BuildContext context, String selectedPlantType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Hero illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_enhance_outlined,
                      size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Deteksi Penyakit Daun',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Foto daun untuk analisis penyakit\nmenggunakan kecerdasan buatan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Plant type selector
          _PlantTypeSelector(
            selectedPlantType: selectedPlantType,
            onChanged: (value) {
              context.read<ScannerBloc>().add(SetPlantType(value));
            },
          ),

          const SizedBox(height: 28),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.read<ScannerBloc>().add(PickImage(ImageSource.camera)),
              icon: const Icon(Icons.camera_alt, size: 22),
              label: const Text(
                'Gunakan Kamera',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.read<ScannerBloc>().add(PickImage(ImageSource.gallery)),
              icon: const Icon(Icons.photo_library_outlined, size: 22),
              label: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // History shortcut
          TextButton.icon(
            onPressed: () => _openHistory(context),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Lihat Riwayat Deteksi'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, ScannerSuccess state) {
    final isHealthy = state.label.toLowerCase().contains('sehat') ||
        state.label.toLowerCase().contains('healthy');
    final statusColor =
        isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    final statusBgColor = statusColor.withOpacity(0.08);

    final disease = state.pestData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Hero(
            tag: 'scan_image',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(state.imagePath),
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Hasil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHealthy
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                    color: statusColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Hasil Analisis AI',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  state.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Confidence bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tingkat Kepercayaan',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${(state.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.confidence,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Plant type info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_outlined,
                          size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        'Jenis: ${state.plantType}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (disease != null) ...[
            // Deskripsi Penyakit
            if (disease['deskripsi_penyakit'] != null) ...[
              _buildInfoSection(
                  'Deskripsi Penyakit', disease['deskripsi_penyakit']),
              const SizedBox(height: 16),
            ],

            // Penanganan
            if (disease['penanganan'] != null) ...[
              _buildInfoSection('Langkah Penanganan', disease['penanganan']),
              const SizedBox(height: 16),
            ],

            // Obat (Highlight Section)
            if (disease['obat'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medication_liquid, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Rekomendasi Obat',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      disease['obat'],
                      style:
                          TextStyle(color: Colors.green.shade900, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ] else if (state.label != 'Sehat' &&
              state.label != 'Tidak Terdeteksi') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail untuk penyakit ini belum tersedia di database.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openHistory(context),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Lihat Riwayat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<ScannerBloc>().add(ResetScanner()),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Foto Ulang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }
}

// ─── Plant Type Selector Widget ────────────────────────────────────────────────

class _PlantTypeSelector extends StatelessWidget {
  final String selectedPlantType;
  final ValueChanged<String> onChanged;

  const _PlantTypeSelector({
    required this.selectedPlantType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_outlined, size: 18, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Pilih Jenis Tanaman',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _plantTypes.map((type) {
              final isSelected = type == selectedPlantType;
              return GestureDetector(
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
