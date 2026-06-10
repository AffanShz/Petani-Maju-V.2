import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Penyakit Tanaman'),
        centerTitle: true,
      ),
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state is ScannerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is ScannerInitial) {
            return _buildInitialView(context);
          }
          
          if (state is ScannerLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is ScannerSuccess) {
            return _buildResultView(context, state);
          }

          if (state is ScannerImagePicked || state is ScannerLoading) {
             // Loading or picked state (usually inference starts automatically)
             return const Center(child: CircularProgressIndicator());
          }

          return _buildInitialView(context);
        },
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_enhance_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'Ambil foto daun tanaman untuk\ndeteksi penyakit otomatis',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => context.read<ScannerBloc>().add(PickImage(ImageSource.camera)),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Gunakan Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.read<ScannerBloc>().add(PickImage(ImageSource.gallery)),
            icon: const Icon(Icons.photo_library),
            label: const Text('Pilih dari Galeri'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, ScannerSuccess state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(state.imagePath),
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const Text('Hasil Analisis AI', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  state.label,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tingkat Kepercayaan: ${(state.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<ScannerBloc>().add(ResetScanner()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Foto Ulang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
