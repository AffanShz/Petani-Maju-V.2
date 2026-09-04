import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrinova/core/constants/colors.dart';
import 'package:agrinova/core/services/cache_service.dart';
import 'package:agrinova/features/premium/widgets/upgrade_to_pro_dialog.dart';
import 'package:agrinova/widgets/app_toast.dart';

class ChatInputBar extends StatefulWidget {
  final bool isStreaming;
  final void Function(String text, String? imagePath) onSend;

  const ChatInputBar({
    super.key,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CacheService _cacheService = CacheService();
  String? _selectedImagePath;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if ((text.isEmpty && _selectedImagePath == null) || widget.isStreaming) {
      return;
    }

    final imageToSend = _selectedImagePath;
    // Pengecekan awal supaya pesan tidak terlanjur terkirim dan terhapus dari
    // kolom input. Penghitungan kuota yang sebenarnya dilakukan ChatbotBloc,
    // agar jalur lain (tombol saran, hasil scan, riwayat) ikut terhitung dan
    // tidak ada penghitungan ganda di sini.
    if (!_cacheService.isPremiumActive()) {
      final sub = _cacheService.getSubscriptionDetails();
      final remaining = sub['remainingFreeChats'] as int? ?? 0;
      if (remaining <= 0) {
        showUpgradeToProDialog(context);
        return;
      }
    }
    _controller.clear();
    setState(() {
      _selectedImagePath = null;
    });

    widget.onSend(text, imageToSend);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      final file = File(image.path);
      if (!await file.exists()) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'File gambar tidak ditemukan.',
            type: ToastType.error,
          );
        }
        return;
      }

      final ext = image.path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Hanya file gambar (JPG, PNG, WEBP) yang didukung.',
            type: ToastType.warning,
          );
        }
        return;
      }

      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Ukuran gambar maksimal 5 MB.',
            type: ToastType.error,
          );
        }
        return;
      }

      setState(() {
        _selectedImagePath = image.path;
      });
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Gagal mengambil gambar: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showImageSourcePicker() {
    if (widget.isStreaming) return;

    final bool isPro = _cacheService.isPremiumActive();
    if (!isPro) {
      final sub = _cacheService.getSubscriptionDetails();
      final remaining = sub['remainingFreeChats'] as int? ?? 0;
      if (remaining <= 0) {
        showUpgradeToProDialog(context);
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sub = _cacheService.getSubscriptionDetails();
        final isPro = _cacheService.isPremiumActive();
        final remaining =
            isPro ? null : (sub['remainingFreeChats'] as int? ?? 0);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lampirkan Foto Pertanian/Perkebunan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!isPro && remaining != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: remaining > 0
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Sisa $remaining/3 chat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: remaining > 0
                                  ? AppColors.primaryGreen
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primaryGreen),
                  ),
                  title: const Text(
                    'Ambil Foto (Kamera)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Foto langsung tanaman, daun berpenyakit, atau hama',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Colors.blue),
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Pilih gambar tersimpan (maks. 5 MB, JPG/PNG)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFileSizeString(String path) {
    try {
      final bytes = File(path).lengthSync();
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInput =
        _controller.text.trim().isNotEmpty || _selectedImagePath != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImagePath != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImagePath!),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Foto Tanaman Terlampir',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _getFileSizeString(_selectedImagePath!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedImagePath = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: widget.isStreaming ? null : _showImageSourcePicker,
                  tooltip: 'Lampirkan Foto',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    backgroundColor: _selectedImagePath != null
                        ? AppColors.primaryGreen.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                  ),
                  icon: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: _selectedImagePath != null
                        ? AppColors.primaryGreen
                        : (widget.isStreaming
                            ? Colors.grey.shade400
                            : Colors.grey.shade700),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isStreaming,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _selectedImagePath != null
                          ? 'Tanyakan sesuatu tentang foto ini...'
                          : 'Tanyakan seputar pertanian & perkebunan...',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    onPressed:
                        (widget.isStreaming || !hasInput) ? null : _handleSend,
                    style: IconButton.styleFrom(
                      backgroundColor: (widget.isStreaming || !hasInput)
                          ? Colors.grey.shade300
                          : AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: widget.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
