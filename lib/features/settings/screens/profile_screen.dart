import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:petani_maju/core/services/cache_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CacheService _cacheService = CacheService();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print("ProfileScreen: initState called");
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (kDebugMode) print("ProfileScreen: Loading profile data...");
      final profile = _cacheService.getUserProfile();
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _imagePath = profile['imagePath'];
      });
      if (kDebugMode) print("ProfileScreen: Data loaded: name=${_nameController.text}, path=$_imagePath");
    } catch (e) {
      if (kDebugMode) print("ProfileScreen Error loading: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'profile.image_error'.tr()}$e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cacheService.saveUserProfile(
        name: _nameController.text,
        imagePath: _imagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.save_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'profile.save_error'.tr()}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print("ProfileScreen: build called");
    
    // Determine image provider safely
    ImageProvider? imageProvider;
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      final file = File(_imagePath!);
      // We check existence only for rendering logic, avoiding crash if missing
      imageProvider = FileImage(file);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'profile.edit_title'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                    // Use onBackgroundImageError to handle missing files gracefully
                    onBackgroundImageError: imageProvider != null
                        ? (exception, stackTrace) {
                            if (kDebugMode) print("Profile Image Error: $exception");
                          }
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'profile.name_label'.tr(),
                hintText: 'profile.name_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'profile.save_button'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
