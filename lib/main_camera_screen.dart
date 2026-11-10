import 'package:dispensiamo/camera_screen.dart';
import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/result_screen.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MainCameraScreen extends StatelessWidget {
  const MainCameraScreen({
    super.key,
    required this.onProductsImported,
  });

  final ValueChanged<int> onProductsImported;

  Future<void> _selectFromGallery(BuildContext context) async {
    final strings = AppStrings.of(context);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imagePath: image.path,
            onProductsImported: onProductsImported,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.galleryError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                strings.homeHeadline,
                style: const TextStyle(
                  fontSize: 36,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.homeDescription,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(
                          onProductsImported: onProductsImported,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(strings.takePhoto),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _selectFromGallery(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFFE2E2E2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(strings.chooseFromGallery),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
