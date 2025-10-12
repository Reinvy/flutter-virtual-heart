import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../services/pdf_service.dart';
import '../app_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controller for text input field
  final TextEditingController _messageController = TextEditingController();

  // Focus node for text input field
  final FocusNode _focusNode = FocusNode();

  // List to store chat messages
  List<Map<String, dynamic>> _messages = [];

  // Single document storage (support only one document at a time)
  String? _document;

  // State variables
  bool _isLoading = false;
  bool _isIngesting = false;
  String? _errorMessage;

  // Chat title
  String _chatTitle = 'New Chat';

  // PDF context management
  String? _pdfContext;
  bool _usePdfContext = true;
  double _contextUsageRatio = 0.7; // 70% of max tokens for context
  String? _currentPdfName;

  // App state
  final AppState _appState = AppState();

  // SharedPreferences for storing chat data
  late SharedPreferences _prefs;

  // Scroll controller for auto-scrolling to the latest message
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    _prefs = await SharedPreferences.getInstance();
    // Load PDF cache for faster access
    await PdfService.loadCache();
    await _loadMessages();
    await _loadDocuments();
    await _loadPdfContext();
    await _loadChatTitle();
  }

  Future<void> _loadPdfContext() async {
    try {
      if (await PdfService.hasStoredPdfForChat(widget.chatId)) {
        final pdfInfo = await PdfService.loadPdfDataForChat(widget.chatId);

        if (pdfInfo != null) {
          setState(() {
            _pdfContext = pdfInfo['text'];
            _currentPdfName = pdfInfo['name'];
          });
          print('Loaded PDF context for chat ${widget.chatId}: ${pdfInfo['name']}');
        } else {
          print('PDF context data is incomplete for chat ${widget.chatId}');
          // Clear any incomplete data
          await PdfService.clearPdfDataForChat(widget.chatId);
          setState(() {
            _pdfContext = null;
            _currentPdfName = null;
          });
        }
      } else {
        print('No stored PDF found for chat ${widget.chatId}');
        setState(() {
          _pdfContext = null;
          _currentPdfName = null;
        });
      }
    } catch (e) {
      print('Error loading PDF context for chat ${widget.chatId}: $e');
      setState(() {
        _pdfContext = null;
        _currentPdfName = null;
      });
    }
  }

  Future<void> _loadChatTitle() async {
    try {
      String? chatsJson = _prefs.getString('chats_list');

      if (chatsJson != null && chatsJson.isNotEmpty) {
        try {
          final List<dynamic> decodedChats = jsonDecode(chatsJson);
          final List<Map<String, dynamic>> chats = decodedChats
              .map((dynamic item) => Map<String, dynamic>.from(item))
              .toList();
          final int chatIndex = chats.indexWhere((chat) => chat['id'] == widget.chatId);

          if (chatIndex != -1) {
            setState(() {
              _chatTitle = chats[chatIndex]['title'] ?? 'New Chat';
            });
            print('Loaded chat title: $_chatTitle for chat ${widget.chatId}');
          } else {
            print('Chat ${widget.chatId} not found in chats list, using default title');
            setState(() {
              _chatTitle = 'New Chat';
            });
          }
        } catch (e) {
          print('Error loading chat title: $e');
          setState(() {
            _chatTitle = 'New Chat';
          });
        }
      } else {
        print('No chats list found in storage, using default title');
        setState(() {
          _chatTitle = 'New Chat';
        });
      }
    } catch (e) {
      print('Error in _loadChatTitle: $e');
      setState(() {
        _chatTitle = 'New Chat';
      });
    }
  }

  Future<void> _loadMessages() async {
    try {
      final String key = 'messages_${widget.chatId}';
      String? messagesJson = _prefs.getString(key);

      if (messagesJson != null && messagesJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(messagesJson);
          setState(() {
            _messages = decoded.map((dynamic item) => Map<String, dynamic>.from(item)).toList();
          });
          print('Loaded ${_messages.length} messages for chat ${widget.chatId}');
        } catch (e) {
          print('Error decoding messages data: $e');
          await _createDefaultMessages();
        }
      } else {
        await _createDefaultMessages();
      }
    } catch (e) {
      print('Error loading messages: $e');
      await _createDefaultMessages();
    }
  }

  Future<void> _createDefaultMessages() async {
    setState(() {
      _messages = [
        {
          'text': 'Hello! I\'m your AI assistant. How can I help you today?',
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];
    });
    await _saveMessages();
    print('Created default messages for chat ${widget.chatId}');
  }

  Future<void> _loadDocuments() async {
    try {
      final String key = 'documents_${widget.chatId}';
      String? docsJson = _prefs.getString(key);

      if (docsJson != null && docsJson.isNotEmpty) {
        try {
          setState(() {
            _document = jsonDecode(docsJson);
          });
          print('Loaded document for chat ${widget.chatId}: $_document');
        } catch (e) {
          print('Error decoding documents data: $e');
          setState(() {
            _document = null;
          });
        }
      } else {
        setState(() {
          _document = null;
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        _document = null;
      });
    }
  }

  Future<void> _saveMessages() async {
    try {
      final String key = 'messages_${widget.chatId}';
      final String messagesJson = jsonEncode(_messages);
      await _prefs.setString(key, messagesJson);
      print('Saved ${_messages.length} messages for chat ${widget.chatId}');
    } catch (e) {
      print('Error saving messages: $e');
      // Show error message to user if possible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save messages: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveDocuments() async {
    try {
      final String key = 'documents_${widget.chatId}';
      await _prefs.setString(key, jsonEncode(_document));
      print('Saved document for chat ${widget.chatId}: $_document');
    } catch (e) {
      print('Error saving documents: $e');
      // Show error message to user if possible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save documents: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateChatMetadata(String lastMessage) async {
    try {
      String? chatsJson = _prefs.getString('chats_list');

      if (chatsJson != null && chatsJson.isNotEmpty) {
        try {
          final List<dynamic> decodedChats = jsonDecode(chatsJson);
          final List<Map<String, dynamic>> chats = decodedChats
              .map((dynamic item) => Map<String, dynamic>.from(item))
              .toList();
          final int chatIndex = chats.indexWhere((chat) => chat['id'] == widget.chatId);

          if (chatIndex != -1) {
            chats[chatIndex]['lastMessage'] = lastMessage;
            chats[chatIndex]['date'] = DateTime.now().toIso8601String();
            final String updatedChatsJson = jsonEncode(chats);
            await _prefs.setString('chats_list', updatedChatsJson);
            print('Updated metadata for chat ${widget.chatId}');
          } else {
            print('Chat ${widget.chatId} not found in chats list');
          }
        } catch (e) {
          print('Error updating chat metadata: $e');
        }
      } else {
        print('No chats list found in storage');
      }
    } catch (e) {
      print('Error in _updateChatMetadata: $e');
    }
  }

  Future<void> _updateChatTitle(String newTitle) async {
    try {
      String? chatsJson = _prefs.getString('chats_list');

      if (chatsJson != null && chatsJson.isNotEmpty) {
        try {
          final List<dynamic> decodedChats = jsonDecode(chatsJson);
          final List<Map<String, dynamic>> chats = decodedChats
              .map((dynamic item) => Map<String, dynamic>.from(item))
              .toList();
          final int chatIndex = chats.indexWhere((chat) => chat['id'] == widget.chatId);

          if (chatIndex != -1) {
            chats[chatIndex]['title'] = newTitle;
            final String updatedChatsJson = jsonEncode(chats);
            await _prefs.setString('chats_list', updatedChatsJson);

            setState(() {
              _chatTitle = newTitle;
            });

            print('Updated chat title to: $newTitle for chat ${widget.chatId}');
          } else {
            print('Chat ${widget.chatId} not found in chats list');
          }
        } catch (e) {
          print('Error updating chat title: $e');
        }
      } else {
        print('No chats list found in storage');
      }
    } catch (e) {
      print('Error in _updateChatTitle: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    _focusNode.unfocus();

    // Add user message
    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _errorMessage = null;
    });

    // Save messages to storage
    _saveMessages();

    // Update chat metadata
    _updateChatMetadata(message);

    // Update chat title if it's the first user message
    if (_messages.length == 1) {
      // Only user message exists, update title
      String newTitle = message.length > 20 ? '${message.substring(0, 20)}...' : message;
      _updateChatTitle(newTitle);
    }

    // Scroll to bottom after adding user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Generate AI response using model service
    _generateAIResponse(message);
  }

  Future<void> _generateAIResponse(String userMessage) async {
    if (!_appState.isModelInitialized) {
      setState(() {
        _errorMessage = 'Model is not ready yet. Please wait.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate AI response using model service with PDF context
      final aiResponse = await _appState.modelService.generateResponse(
        userMessage,
        pdfContext: _pdfContext,
        usePdfContext: _usePdfContext,
        contextRatio: _contextUsageRatio,
      );

      setState(() {
        _messages.add({
          'text': aiResponse,
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
          'usedPdfContext': _usePdfContext && _pdfContext != null,
        });
        _isLoading = false;
      });

      // Save messages after AI response
      _saveMessages();

      // Scroll to bottom after adding AI response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get response. Please try again. Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final text = message['text'] as String;
    final DateTime timestamp;
    if (message['timestamp'] is String) {
      timestamp = DateTime.parse(message['timestamp']);
    } else {
      timestamp = message['timestamp'] as DateTime;
    }
    final usedPdfContext = message['usedPdfContext'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary, size: 18),
            )
          else
            const SizedBox(width: 32), // Spacer for user messages

          const SizedBox(width: 8),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name and timestamp
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isUser ? 'You' : 'AI Assistant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PDF context indicator
                      if (!isUser && usedPdfContext)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Based on PDF: ${_currentPdfName ?? "document"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      GptMarkdown(
                        text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),

                      // Message actions (copy, share)
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Copy button
                              InkWell(
                                onTap: () {
                                  // Copy message to clipboard
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Message copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: isUser
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // View source button if PDF context was used
                              if (usedPdfContext)
                                InkWell(
                                  onTap: () {
                                    _showPdfSourceDialog(text);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.source,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // User avatar
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            )
          else
            const SizedBox(width: 32), // Spacer for AI messages
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    try {
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Invalid time';
    }
  }

  Future<void> _addDocument() async {
    // Show loading indicator
    setState(() {
      _isIngesting = true;
      _errorMessage = null;
    });

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.upload_file, color: Colors.blue),
              SizedBox(width: 8),
              Text('Processing PDF'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Please wait while we process your PDF...'),
              const SizedBox(height: 8),
              Text(
                'Chat: ${widget.chatId.substring(0, min(8, widget.chatId.length))}...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result != null && result.files.isNotEmpty) {
        String fileName = result.files.single.name;
        String? filePath = result.files.single.path;

        if (filePath != null) {
          final File file = File(filePath);

          // Validasi file PDF menggunakan PdfService
          try {
            String validationMessage = await PdfService.validatePdfFile(file);
            print('PDF validation: $validationMessage');

            // Jika file PDF, ekstrak teks
            if (fileName.toLowerCase().endsWith('.pdf')) {
              try {
                String extractedText = await PdfService.extractTextFromPdfForChat(
                  widget.chatId,
                  file,
                );

                setState(() {
                  _document = fileName;
                  _pdfContext = extractedText;
                  _currentPdfName = fileName;
                  _isIngesting = false;
                });
                await _saveDocuments();

                // Update chat metadata to indicate this chat has documents
                _updateChatMetadata('Uploaded PDF: $fileName');

                // Show a snackbar to confirm document was added
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PDF "$fileName" berhasil diupload (${extractedText.length} karakter)',
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }

                print('PDF uploaded and processed for chat ${widget.chatId}: $fileName');
              } catch (e) {
                print('Error processing PDF: $e');
                setState(() {
                  _isIngesting = false;
                });

                // Show detailed error message
                String errorMessage = 'Gagal memproses PDF: ${e.toString()}';
                if (e.toString().contains('2MB')) {
                  errorMessage = 'Ukuran file PDF melebihi batas maksimal 2MB';
                } else if (e.toString().contains('tidak ditemukan')) {
                  errorMessage = 'File PDF tidak ditemukan atau tidak dapat diakses';
                } else if (e.toString().contains('tidak valid')) {
                  errorMessage = 'File PDF tidak valid atau rusak';
                } else if (e.toString().contains('teks')) {
                  errorMessage = 'Tidak ada teks yang dapat diekstrak dari PDF ini';
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage)),
                        ],
                      ),
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            }
          } catch (validationError) {
            print('PDF validation failed: $validationError');
            setState(() {
              _isIngesting = false;
            });

            // Show detailed validation error
            String errorMessage = 'Validasi PDF gagal: ${validationError.toString()}';
            if (validationError.toString().contains('2MB')) {
              errorMessage = 'Ukuran file PDF melebihi batas maksimal 2MB';
            } else if (validationError.toString().contains('tidak ditemukan')) {
              errorMessage = 'File PDF tidak ditemukan';
            } else if (validationError.toString().contains('harus berformat PDF')) {
              errorMessage = 'File harus berformat PDF';
            } else if (validationError.toString().contains('kosong')) {
              errorMessage = 'File PDF kosong';
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorMessage)),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          }
        }
      } else {
        // User cancelled file selection
        setState(() {
          _isIngesting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pemilihan file dibatalkan'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding document: $e');
      setState(() {
        _isIngesting = false;
      });

      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show detailed error message
      String errorMessage = 'Gagal menambahkan dokumen: ${e.toString()}';
      if (e.toString().contains('permission')) {
        errorMessage = 'Izin akses file ditolak. Silakan coba lagi.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Penyimpanan tidak tersedia. Silakan periksa ruang penyimpanan Anda.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  // Show dialog to display PDF source information
  void _showPdfSourceDialog(String aiResponse) {
    if (_pdfContext == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Context Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF: ${_currentPdfName ?? "Unknown"}'),
            const SizedBox(height: 8),
            Text('Teks ter-ekstrak: ${_pdfContext!.length} karakter'),
            const SizedBox(height: 16),
            const Text('Konteks PDF digunakan untuk merespons pertanyaan Anda.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  // Remove document
  void _removeDocument() {
    if (_document != null) {
      final removedDoc = _document;
      setState(() {
        _document = null;
        _pdfContext = null;
        _currentPdfName = null;
      });
      _saveDocuments();

      // Clear PDF data for this specific chat
      PdfService.clearPdfDataForChat(widget.chatId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dokumen "$removedDoc" dihapus'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Show PDF context settings
  void _showPdfContextSettings() {
    if (_pdfContext == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Context Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PDF: ${_currentPdfName ?? "Unknown"}'),
            const SizedBox(height: 16),
            Text('Teks ter-ekstrak: ${_pdfContext!.length} karakter'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gunakan konteks PDF:'),
                Switch(
                  value: _usePdfContext,
                  onChanged: (value) {
                    setState(() {
                      _usePdfContext = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rasio penggunaan konteks:'),
                Text('${(_contextUsageRatio * 100).round()}%'),
              ],
            ),
            Slider(
              value: _contextUsageRatio,
              min: 0.1,
              max: 0.9,
              divisions: 8,
              onChanged: (value) {
                setState(() {
                  _contextUsageRatio = value;
                });
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  // Build PDF header widget
  Widget _buildPdfHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PDF Context: ${_currentPdfName ?? "Unknown"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings, size: 16),
                    onPressed: _showPdfContextSettings,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: _removeDocument,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_pdfContext?.length ?? 0} karakter teks ter-ekstrak. '
                    'Konteks PDF akan digunakan ${_usePdfContext ? "secara" : "tidak"} otomatis dalam respons AI.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'rename':
                  final newTitle = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Rename Chat'),
                      content: TextField(
                        decoration: const InputDecoration(hintText: 'Enter new chat title'),
                        controller: TextEditingController(text: _chatTitle),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final title = TextEditingController().text;
                            if (title.isNotEmpty) {
                              Navigator.pop(context, title);
                            }
                          },
                          child: const Text('Rename'),
                        ),
                      ],
                    ),
                  );
                  if (newTitle != null && newTitle.isNotEmpty) {
                    _updateChatTitle(newTitle);
                  }
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Rename Chat')]),
                ),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [Icon(Icons.delete_outline), SizedBox(width: 8), Text('Clear Chat')],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact document section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // PDF icon and status
                Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Document',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (_currentPdfName != null)
                        Text(
                          _currentPdfName!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                // Status indicator
                if (_pdfContext != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Loaded',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PDF context settings button if PDF is available
                    if (_pdfContext != null)
                      IconButton(
                        onPressed: _showPdfContextSettings,
                        icon: Icon(Icons.settings, color: Theme.of(context).primaryColor, size: 16),
                        tooltip: 'PDF Context Settings',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    const SizedBox(width: 4),
                    // Remove button if PDF is available
                    if (_pdfContext != null)
                      IconButton(
                        onPressed: _removeDocument,
                        icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 16),
                        tooltip: 'Remove PDF',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    const SizedBox(width: 4),
                    // Upload button - only show when no document exists
                    if (_pdfContext == null)
                      IconButton(
                        onPressed: _isIngesting ? null : _addDocument,
                        icon: _isIngesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.upload_file,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                        tooltip: 'Upload PDF',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // PDF Header (if PDF is loaded)
          if (_currentPdfName != null && _pdfContext != null) _buildPdfHeader(),

          // Messages display area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Start a conversation!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        // Add animation for new messages
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _buildMessageBubble(_messages[index]),
                        );
                      },
                    ),
            ),
          ),

          // Error message display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                  if (_errorMessage != null && !_appState.isGlobalLoading)
                    TextButton(
                      onPressed: () {
                        _appState.initializeApp();
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Model loading indicator
          if (_appState.isGlobalLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading AI model...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          // AI thinking indicator
          if (_isLoading && _appState.isModelInitialized)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 16),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading && _appState.isModelInitialized,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: (!_isLoading && _appState.isModelInitialized) ? _sendMessage : null,
                    disabledColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              setState(() {
                _messages = [];
                _document = null;
                _pdfContext = null;
                _currentPdfName = null;
              });
              _saveMessages();
              _saveDocuments();

              // Clear PDF data for this specific chat
              await PdfService.clearPdfDataForChat(widget.chatId);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared'), duration: Duration(seconds: 2)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
