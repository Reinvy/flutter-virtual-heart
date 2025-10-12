import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PdfViewerScreen({super.key, required this.filePath, required this.fileName});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int? _totalPages;
  int? _currentPage;
  bool _isLoading = true;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        centerTitle: true,
        actions: [
          if (_totalPages != null && _currentPage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('$_currentPage/$_totalPages', style: const TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages;
                _isLoading = false;
              });
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening PDF: $error'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            onPageError: (page, error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error on page $page: $error'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page;
              });
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: _totalPages != null
          ? FloatingActionButton(
              onPressed: () {
                _showPageJumpDialog();
              },
              child: const Icon(Icons.pageview),
            )
          : null,
    );
  }

  void _showPageJumpDialog() {
    final TextEditingController pageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Enter page number (1-$_totalPages)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final int? page = int.tryParse(pageController.text);
              if (page != null && page > 0 && page <= _totalPages!) {
                Navigator.pop(context);
                _pdfViewController?.setPage(page - 1);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
