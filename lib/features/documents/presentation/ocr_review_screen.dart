import 'dart:io';
import 'package:flutter/material.dart';

class OCRReviewScreen extends StatefulWidget {
  final File imageFile;
  final String? recognizedText;

  const OCRReviewScreen({
    super.key,
    required this.imageFile,
    this.recognizedText,
  });

  @override
  State<OCRReviewScreen> createState() => _OCRReviewScreenState();
}

class _OCRReviewScreenState extends State<OCRReviewScreen> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final lines = (widget.recognizedText ?? '').split('\n').where((line) => line.trim().isNotEmpty).toList();
    _controllers = lines.map((line) => TextEditingController(text: line)).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDone() {
    final correctedText = _controllers.map((c) => c.text).join('\n');
    Navigator.pop(context, correctedText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scanned Text'),
        backgroundColor: theme.colorScheme.surfaceVariant,
        actions: [
          TextButton.icon(
            onPressed: _onDone,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Done'),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview panel
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(child: Image.file(widget.imageFile)),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Editable text panel
          Expanded(
            flex: 3,
            child: _controllers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No text was recognized in the image.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextFormField(
                          controller: _controllers[index],
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onDone,
        label: const Text('Confirm & Use Text'),
        icon: const Icon(Icons.check_circle),
      ),
    );
  }
}
