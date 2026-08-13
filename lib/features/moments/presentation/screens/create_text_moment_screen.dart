import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/moment_repository.dart';

class CreateTextMomentScreen extends StatefulWidget {
  const CreateTextMomentScreen({super.key});

  @override
  State<CreateTextMomentScreen> createState() => _CreateTextMomentScreenState();
}

class _CreateTextMomentScreenState extends State<CreateTextMomentScreen> {
  final _momentRepository = MomentRepository();
  final _textController = TextEditingController();
  final List<Color> _colors = [
    AppColors.primary,
    AppColors.secondary,
    const Color(0xFF673AB7),
    const Color(0xFFE91E63),
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFFF9800),
    const Color(0xFF333333),
  ];
  int _selectedColorIndex = 0;
  bool _isUploading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _shareMoment() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final colorHex = '#${_colors[_selectedColorIndex].value.toRadixString(16).substring(2)}';
      await _momentRepository.createTextMoment(_textController.text.trim(), backgroundColor: colorHex);
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
      backgroundColor: _colors[_selectedColorIndex],
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
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: TextField(
                controller: _textController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Share a thought...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                maxLength: 150,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColorIndex == index ? Colors.white : Colors.white24,
                        width: 2,
                      ),
                    ),
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
