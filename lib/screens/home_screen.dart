import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'pdf_viewer_screen.dart'; // Correctly imports the viewer screen

class HomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  /// The core logic for picking a PDF file and navigating to the viewer screen.
  Future<void> _pickAndOpenPdf(BuildContext context) async {
    try {
      // Use the file picker to select a single PDF file.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        // We no longer need withData: true, but it doesn't hurt to leave it.
      );

      // If the user picked a file and the path is valid...
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;

        // Navigate to the PDFViewerScreen.
        // THIS IS THE CORRECTED PART: We no longer pass 'pdfBytes'.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(
              pdfPath: file.path!,
              fileName: file.name,
            ),
          ),
        );
      } else {
        // User canceled the file picker.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File picking canceled.')),
        );
      }
    } catch (e) {
      // Handle any errors that might occur during file picking.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PageFlow'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: onThemeToggle,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Convert PDF to Readable HTML',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Select a PDF document to convert it into a simple, reflowable HTML format for easier mobile reading.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _pickAndOpenPdf(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('Select PDF Document'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
