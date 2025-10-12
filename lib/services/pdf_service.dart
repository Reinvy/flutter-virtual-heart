import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;

class PdfService {
  static const String _pdfTextKey = 'pdf_extracted_text';
  static const String _pdfPathKey = 'pdf_file_path';
  static const String _pdfNameKey = 'pdf_file_name';
  static const String _pdfCacheKey = 'pdf_cache_data';
  static const String _pdfCacheTimestampKey = 'pdf_cache_timestamp';
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB
  static const Duration cacheExpiry = Duration(days: 7); // Cache expires after 7 days

  // In-memory cache for faster access
  static String? _cachedPdfText;
  static String? _cachedPdfName;
  static DateTime? _cacheTimestamp;

  /// Mengekstrak teks dari file PDF dengan caching
  static Future<String> extractTextFromPdf(File pdfFile) async {
    try {
      final fileName = pdfFile.uri.pathSegments.last;

      // Check if we have a valid cache for this file
      if (_isCacheValid(fileName)) {
        print('Using cached PDF text for $fileName');
        return _cachedPdfText!;
      }

      // Validasi ukuran file
      final fileSize = await pdfFile.length();
      if (fileSize > maxFileSize) {
        throw Exception('Ukuran file PDF (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB) melebihi batas maksimal ${maxFileSize ~/ (1024 * 1024)}MB');
      }

      // Validasi ekstensi file
      if (!pdfFile.path.toLowerCase().endsWith('.pdf')) {
        throw Exception('File yang diupload bukan berformat PDF');
      }

      // Validasi apakah file bisa dibaca
      if (!await pdfFile.exists()) {
        throw Exception('File PDF tidak ditemukan atau tidak dapat diakses');
      }

      // Baca file sebagai bytes
      final Uint8List bytes = await pdfFile.readAsBytes();

      // Validasi apakah file PDF valid
      if (bytes.isEmpty) {
        throw Exception('File PDF kosong atau tidak valid');
      }

      // Proses ekstraksi teks
      String extractedText = await _processPdfBytes(bytes);

      // Validasi hasil ekstraksi
      if (extractedText.trim().isEmpty) {
        throw Exception('Tidak ada teks yang dapat diekstrak dari PDF ini. File mungkin berisi gambar atau format tidak didukung.');
      }

      // Simpan hasil ekstraksi ke cache dan SharedPreferences
      await _savePdfData(pdfFile.path, fileName, extractedText);
      await _updateCache(fileName, extractedText);

      return extractedText;
    } catch (e) {
      print('Error extracting text from PDF: $e');
      throw Exception('Gagal mengekstrak teks dari PDF: ${e.toString()}');
    }
  }

  /// Memproses bytes PDF untuk mengekstrak teks
  static Future<String> _processPdfBytes(Uint8List bytes) async {
    try {
      // Load PDF document menggunakan Syncfusion
      final syncfusion_pdf.PdfDocument document = syncfusion_pdf.PdfDocument(inputBytes: bytes);

      // Ekstrak teks dari PDF
      String extractedText = '';
      final int pageCount = document.pages.count;
      
      if (pageCount == 0) {
        document.dispose();
        throw Exception('PDF tidak memiliki halaman yang valid');
      }

      for (int i = 0; i < pageCount; i++) {
        try {
          final String pageText = syncfusion_pdf.PdfTextExtractor(
            document,
          ).extractText(startPageIndex: i);
          
          extractedText += '--- Halaman ${i + 1} ---\n';
          extractedText += pageText.isNotEmpty ? pageText : '[Halaman ini tidak mengandung teks]\n';
          extractedText += '\n\n';
        } catch (pageError) {
          print('Error processing page ${i + 1}: $pageError');
          extractedText += '--- Halaman ${i + 1} ---\n';
          extractedText += '[Gagal memproses halaman ini]\n\n';
        }
      }

      // Tutup dokumen
      document.dispose();

      // Clean up the extracted text
      extractedText = extractedText.trim();
      
      return extractedText.isNotEmpty
          ? extractedText
          : 'Tidak ada teks yang dapat diekstrak dari PDF ini.';
    } catch (e) {
      print('Error processing PDF bytes: $e');
      throw Exception('Gagal memproses PDF: ${e.toString()}');
    }
  }

  /// Menyimpan data PDF ke SharedPreferences
  static Future<void> _savePdfData(String path, String name, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pdfPathKey, path);
      await prefs.setString(_pdfNameKey, name);
      await prefs.setString(_pdfTextKey, text);
      print('Saved PDF data: $name (${text.length} characters)');
    } catch (e) {
      print('Error saving PDF data: $e');
      throw Exception('Failed to save PDF data: ${e.toString()}');
    }
  }

  /// Memeriksa apakah cache masih valid
  static bool _isCacheValid(String fileName) {
    if (_cachedPdfText == null || _cachedPdfName == null || _cacheTimestamp == null) {
      return false;
    }

    // Check if the cached file is the same as the requested file
    if (_cachedPdfName != fileName) {
      return false;
    }

    // Check if cache has expired
    final now = DateTime.now();
    if (now.difference(_cacheTimestamp!) > cacheExpiry) {
      print('PDF cache expired for $fileName');
      return false;
    }

    return true;
  }

  /// Memperbarui cache dengan data PDF baru
  static Future<void> _updateCache(String fileName, String extractedText) async {
    _cachedPdfName = fileName;
    _cachedPdfText = extractedText;
    _cacheTimestamp = DateTime.now();

    // Also save to persistent cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pdfCacheKey, extractedText);
    await prefs.setString(_pdfNameKey, fileName);
    await prefs.setString(_pdfCacheTimestampKey, _cacheTimestamp!.toIso8601String());

    print('Updated PDF cache for $fileName (${extractedText.length} characters)');
  }

  /// Memuat cache dari penyimpanan persisten
  static Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedText = prefs.getString(_pdfCacheKey);
      final cachedName = prefs.getString(_pdfNameKey);
      final cachedTimestampStr = prefs.getString(_pdfCacheTimestampKey);

      if (cachedText != null && cachedName != null && cachedTimestampStr != null) {
        final cachedTimestamp = DateTime.parse(cachedTimestampStr);
        final now = DateTime.now();

        // Check if cache has expired
        if (now.difference(cachedTimestamp) <= cacheExpiry) {
          _cachedPdfText = cachedText;
          _cachedPdfName = cachedName;
          _cacheTimestamp = cachedTimestamp;
          print('Loaded PDF cache from storage for $cachedName');
        } else {
          print('PDF cache in storage has expired');
          await clearCache();
        }
      }
    } catch (e) {
      print('Error loading PDF cache: $e');
    }
  }

  /// Membersihkan cache
  static Future<void> clearCache() async {
    _cachedPdfText = null;
    _cachedPdfName = null;
    _cacheTimestamp = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pdfCacheKey);
    await prefs.remove(_pdfCacheTimestampKey);

    print('Cleared PDF cache');
  }

  /// Mendapatkan teks PDF yang tersimpan (dengan cache)
  static Future<String?> getStoredPdfText() async {
    try {
      // Try to load cache if not already loaded
      if (_cachedPdfText == null) {
        await loadCache();
      }

      // If we still don't have cached text, fall back to the old method
      if (_cachedPdfText == null) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_pdfTextKey);
      }

      return _cachedPdfText;
    } catch (e) {
      print('Error getting stored PDF text: $e');
      return null;
    }
  }

  /// Mendapatkan path file PDF yang tersimpan
  static Future<String?> getStoredPdfPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pdfPathKey);
    } catch (e) {
      print('Error getting stored PDF path: $e');
      return null;
    }
  }

  /// Mendapatkan nama file PDF yang tersimpan
  static Future<String?> getStoredPdfName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pdfNameKey);
    } catch (e) {
      print('Error getting stored PDF name: $e');
      return null;
    }
  }

  /// Membersihkan data PDF yang tersimpan
  static Future<void> clearStoredPdfData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pdfPathKey);
      await prefs.remove(_pdfNameKey);
      await prefs.remove(_pdfTextKey);

      // Also clear the cache
      await clearCache();

      print('Cleared all stored PDF data');
    } catch (e) {
      print('Error clearing stored PDF data: $e');
      throw Exception('Failed to clear stored PDF data: ${e.toString()}');
    }
  }

  /// Mengecek apakah ada PDF yang tersimpan
  static Future<bool> hasStoredPdf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPath = prefs.containsKey(_pdfPathKey);
      final hasName = prefs.containsKey(_pdfNameKey);
      final hasText = prefs.containsKey(_pdfTextKey);

      // All three keys must exist for a valid stored PDF
      return hasPath && hasName && hasText;
    } catch (e) {
      print('Error checking if PDF is stored: $e');
      return false;
    }
  }

  /// Mendapatkan informasi PDF yang tersimpan
  static Future<Map<String, dynamic>?> getStoredPdfInfo() async {
    try {
      if (!await hasStoredPdf()) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_pdfPathKey);
      final name = prefs.getString(_pdfNameKey);
      final text = prefs.getString(_pdfTextKey);

      if (path == null || name == null || text == null) {
        return null;
      }

      return {
        'path': path,
        'name': name,
        'text': text,
        'textLength': text.length,
        'hasText': text.trim().isNotEmpty,
      };
    } catch (e) {
      print('Error getting stored PDF info: $e');
      return null;
    }
  }

  /// Memvalidasi file PDF
  static Future<String> validatePdfFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('Ukuran file (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB) melebihi batas maksimal 2MB');
      }

      // Check file extension
      if (!file.path.toLowerCase().endsWith('.pdf')) {
        throw Exception('File harus berformat PDF');
      }

      // Check if file is readable
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File PDF kosong');
      }

      // Try to load PDF to validate it's a valid PDF
      try {
        final syncfusion_pdf.PdfDocument document = syncfusion_pdf.PdfDocument(inputBytes: bytes);
        final pageCount = document.pages.count;
        document.dispose();

        if (pageCount == 0) {
          throw Exception('PDF tidak memiliki halaman yang valid');
        }

        return 'File PDF valid dengan $pageCount halaman';
      } catch (pdfError) {
        throw Exception('File PDF tidak valid atau rusak: ${pdfError.toString()}');
      }
    } catch (e) {
      throw Exception('Validasi gagal: ${e.toString()}');
    }
  }

  /// Menyimpan data PDF untuk chat tertentu
  static Future<void> savePdfDataForChat(String chatId, String path, String name, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String textKey = 'pdf_extracted_text_$chatId';
      final String pathKey = 'pdf_file_path_$chatId';
      final String nameKey = 'pdf_file_name_$chatId';
      
      await prefs.setString(pathKey, path);
      await prefs.setString(nameKey, name);
      await prefs.setString(textKey, text);
      print('Saved PDF data for chat $chatId: $name (${text.length} characters)');
    } catch (e) {
      print('Error saving PDF data for chat $chatId: $e');
      throw Exception('Failed to save PDF data: ${e.toString()}');
    }
  }

  /// Memuat data PDF untuk chat tertentu
  static Future<Map<String, dynamic>?> loadPdfDataForChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String textKey = 'pdf_extracted_text_$chatId';
      final String pathKey = 'pdf_file_path_$chatId';
      final String nameKey = 'pdf_file_name_$chatId';
      
      final path = prefs.getString(pathKey);
      final name = prefs.getString(nameKey);
      final text = prefs.getString(textKey);

      if (path == null || name == null || text == null) {
        return null;
      }

      return {
        'path': path,
        'name': name,
        'text': text,
        'textLength': text.length,
        'hasText': text.trim().isNotEmpty,
      };
    } catch (e) {
      print('Error loading PDF data for chat $chatId: $e');
      return null;
    }
  }

  /// Membersihkan data PDF untuk chat tertentu
  static Future<void> clearPdfDataForChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String textKey = 'pdf_extracted_text_$chatId';
      final String pathKey = 'pdf_file_path_$chatId';
      final String nameKey = 'pdf_file_name_$chatId';
      
      await prefs.remove(pathKey);
      await prefs.remove(nameKey);
      await prefs.remove(textKey);
      print('Cleared PDF data for chat $chatId');
    } catch (e) {
      print('Error clearing PDF data for chat $chatId: $e');
      throw Exception('Failed to clear PDF data: ${e.toString()}');
    }
  }

  /// Mengecek apakah ada PDF yang tersimpan untuk chat tertentu
  static Future<bool> hasStoredPdfForChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String textKey = 'pdf_extracted_text_$chatId';
      final String pathKey = 'pdf_file_path_$chatId';
      final String nameKey = 'pdf_file_name_$chatId';
      
      final hasPath = prefs.containsKey(pathKey);
      final hasName = prefs.containsKey(nameKey);
      final hasText = prefs.containsKey(textKey);

      // All three keys must exist for a valid stored PDF
      return hasPath && hasName && hasText;
    } catch (e) {
      print('Error checking if PDF is stored for chat $chatId: $e');
      return false;
    }
  }

  /// Mengekstrak teks dari file PDF untuk chat tertentu
  static Future<String> extractTextFromPdfForChat(String chatId, File pdfFile) async {
    try {
      final fileName = pdfFile.uri.pathSegments.last;

      // Validasi ukuran file
      final fileSize = await pdfFile.length();
      if (fileSize > maxFileSize) {
        throw Exception('Ukuran file PDF (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB) melebihi batas maksimal 2MB');
      }

      // Validasi ekstensi file
      if (!pdfFile.path.toLowerCase().endsWith('.pdf')) {
        throw Exception('File yang diupload bukan berformat PDF');
      }

      // Validasi apakah file bisa dibaca
      if (!await pdfFile.exists()) {
        throw Exception('File PDF tidak ditemukan atau tidak dapat diakses');
      }

      // Baca file sebagai bytes
      final Uint8List bytes = await pdfFile.readAsBytes();

      // Validasi apakah file PDF valid
      if (bytes.isEmpty) {
        throw Exception('File PDF kosong atau tidak valid');
      }

      // Proses ekstraksi teks
      String extractedText = await _processPdfBytes(bytes);

      // Validasi hasil ekstraksi
      if (extractedText.trim().isEmpty) {
        throw Exception('Tidak ada teks yang dapat diekstrak dari PDF ini. File mungkin berisi gambar atau format tidak didukung.');
      }

      // Simpan hasil ekstraksi ke SharedPreferences untuk chat ini
      await savePdfDataForChat(chatId, pdfFile.path, fileName, extractedText);

      return extractedText;
    } catch (e) {
      print('Error extracting text from PDF for chat $chatId: $e');
      throw Exception('Gagal mengekstrak teks dari PDF: ${e.toString()}');
    }
  }
}
