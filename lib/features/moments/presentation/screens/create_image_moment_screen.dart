import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/moment_repository.dart';


class CreateImageMomentScreen extends StatefulWidget {
  final XFile image;
  const CreateImageMomentScreen({super.key, required this.image});

  @override
  State<CreateImageMomentScreen> createState() => _CreateImageMomentScreenState();
}

class _CreateImageMomentScreenState extends State<CreateImageMomentScreen> {
  final _momentRepository = MomentRepository();
  final _captionController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _shareMoment() async {
    setState(() => _isUploading = true);
    try {
      await _momentRepository.createImageMoment(
        File(widget.image.path),
        caption: _captionController.text.trim(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share moment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _shareMoment,
              child: const Text('SHARE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Image.file(
              File(widget.image.path),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
                ),
                child: TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
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
