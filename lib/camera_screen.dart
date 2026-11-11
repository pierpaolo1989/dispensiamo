import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:dispensiamo/l10n/app_strings.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.onProductsImported});

  final ValueChanged<int> onProductsImported;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.camera)),
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    strings.cameraUnavailable,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.white),
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(color: AppColors.acidGreen),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();
                    final scanDate = DateTime.now();
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultScreen(
                          imagePath: image.path,
                          scanDate: scanDate,
                          onProductsImported: widget.onProductsImported,
                        ),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.cameraError(error)),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 4),
                    color: AppColors.acidGreen,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.black,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
