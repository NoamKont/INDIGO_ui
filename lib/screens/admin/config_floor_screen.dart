import 'package:flutter/material.dart';

class YamlUploadForm extends StatelessWidget {
  const YamlUploadForm({super.key});

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('YAML Config Upload'),
        backgroundColor: const Color(0xFF225FFF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: inputDecoration.copyWith(
                hintText: 'Precision (e.g. 0.1)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: inputDecoration.copyWith(
                hintText: 'Wall Layers (comma-separated)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: inputDecoration.copyWith(
                hintText: 'Door Layers (comma-separated)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: inputDecoration.copyWith(
                hintText: 'Roof Layers (comma-separated)',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  //TODO Handle submit and upload
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF225FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit and Upload',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
