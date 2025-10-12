import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'screen/chat_screen.dart';
import 'app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  late SharedPreferences _prefs;
  bool _isAscending = false; // Default to newest first
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      String? chatsJson = _prefs.getString('chats_list');

      if (chatsJson != null && chatsJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(chatsJson);
          setState(() {
            _chats = decoded.map((dynamic item) => Map<String, dynamic>.from(item)).toList();
            _filteredChats = List.from(_chats);
            _sortChats();
          });
          print('Loaded ${_chats.length} chats from storage');
        } catch (e) {
          print('Error decoding chats data: $e');
        }
      } else {
        print('No chats data found in storage');
      }
    } catch (e) {
      print('Error loading chats: $e');

      // Show error message to user if possible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat data. Created default chats instead.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _sortChats() {
    try {
      setState(() {
        _chats.sort((a, b) {
          try {
            final DateTime dateA;
            final DateTime dateB;

            if (a['date'] is String) {
              dateA = DateTime.parse(a['date']);
            } else {
              dateA = a['date'] as DateTime;
            }

            if (b['date'] is String) {
              dateB = DateTime.parse(b['date']);
            } else {
              dateB = b['date'] as DateTime;
            }

            return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
          } catch (e) {
            print('Error parsing date for chat: $e');
            return 0; // Keep original order if date parsing fails
          }
        });
        _filteredChats = List.from(_chats);
      });

      print('Sorted chats in ${_isAscending ? 'ascending' : 'descending'} order');
    } catch (e) {
      print('Error sorting chats: $e');
      setState(() {
        _filteredChats = List.from(_chats);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sort chats: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _filterChats(String query) {
    try {
      if (query.isEmpty) {
        setState(() {
          _filteredChats = List.from(_chats);
        });
        return;
      }

      setState(() {
        _filteredChats = _chats.where((chat) {
          final title = chat['title'].toString().toLowerCase();
          final lastMessage = chat['lastMessage'].toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return title.contains(searchQuery) || lastMessage.contains(searchQuery);
        }).toList();
      });

      print('Filtered chats with query: "$query", found ${_filteredChats.length} results');
    } catch (e) {
      print('Error filtering chats: $e');
      setState(() {
        _filteredChats = List.from(_chats);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to filter chats: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      final DateTime date;

      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        print('Invalid date type: ${dateValue.runtimeType}');
        return 'Invalid date';
      }

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));

      if (date.isAfter(today)) {
        return DateFormat('h:mm a').format(date);
      } else if (date.isAfter(yesterday) && date.isBefore(today)) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  Future<void> _saveChats() async {
    try {
      if (_chats.isEmpty) return;
      final String chatsJson = jsonEncode(_chats);
      await _prefs.setString('chats_list', chatsJson);
      print('Saved ${_chats.length} chats to storage');
    } catch (e) {
      print('Error saving chats: $e');
      // Show error message to user if possible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save chat data: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Backup chat data to a JSON string
  Future<String> backupChats() async {
    try {
      final Map<String, dynamic> backupData = {
        'chats': _chats,
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final String backupJson = jsonEncode(backupData);
      print('Created backup with ${_chats.length} chats');
      return backupJson;
    } catch (e) {
      print('Error creating backup: $e');
      throw Exception('Failed to create backup: ${e.toString()}');
    }
  }

  // Restore chat data from a JSON string
  Future<bool> restoreChats(String backupJson) async {
    try {
      final Map<String, dynamic> backupData = jsonDecode(backupJson);

      // Validate backup data structure
      if (!backupData.containsKey('chats') ||
          !backupData.containsKey('backupDate') ||
          !backupData.containsKey('version')) {
        throw Exception('Invalid backup format');
      }

      final List<dynamic> restoredChats = backupData['chats'];
      final String backupDate = backupData['backupDate'];
      final String version = backupData['version'];

      print(
        'Restoring backup from $backupDate (version $version) with ${restoredChats.length} chats',
      );

      setState(() {
        _chats = restoredChats.map((dynamic item) => Map<String, dynamic>.from(item)).toList();
        _filteredChats = List.from(_chats);
        _sortChats();
      });

      // Save restored data
      await _saveChats();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat data restored successfully'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e) {
      print('Error restoring backup: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore chat data: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      return false;
    }
  }

  void _editChatName(int index) {
    final controller = TextEditingController(text: _filteredChats[index]['title']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Chat Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a new name for this chat', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Chat name cannot be empty';
                  }
                  if (value.trim().length < 3) {
                    return 'Chat name must be at least 3 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter chat name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                try {
                  final newTitle = controller.text.trim();
                  final chatId = _filteredChats[index]['id'];
                  setState(() {
                    // Update in both lists
                    final chatIndex = _chats.indexWhere((chat) => chat['id'] == chatId);
                    if (chatIndex != -1) {
                      _chats[chatIndex]['title'] = newTitle;
                    }
                    _filteredChats[index]['title'] = newTitle;
                  });
                  _saveChats();
                  Navigator.pop(context);
                  print('Updated chat name to: $newTitle');
                } catch (e) {
                  print('Error updating chat name: $e');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update chat name: ${e.toString()}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteChat(int index) {
    try {
      final chatId = _filteredChats[index]['id'];
      setState(() {
        _chats.removeWhere((chat) => chat['id'] == chatId);
        _filteredChats.removeAt(index);
      });
      _saveChats();
      print('Deleted chat with ID: $chatId');
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chat: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmDelete(int index) {
    try {
      final chatTitle = _filteredChats[index]['title'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "$chatTitle"?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone and all messages in this chat will be permanently deleted.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteChat(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing delete confirmation dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to show delete confirmation: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showActions(int index) {
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context);
                _editChatName(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Chat'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(index);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing actions bottom sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to show actions: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('AI Chat'),
                const SizedBox(width: 8),
                // Model status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _appState.isModelInitialized
                        ? Colors.green
                        : _appState.isGlobalLoading
                        ? Colors.orange
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 247, 244, 244),
            actions: [
              // Model status button
              if (!_appState.isModelInitialized)
                PopupMenuButton<String>(
                  icon: Icon(
                    _appState.isGlobalLoading ? Icons.hourglass_empty : Icons.error_outline,
                    color: _appState.isGlobalLoading ? Colors.orange : Colors.red,
                  ),
                  onSelected: (value) {
                    if (value == 'retry') {
                      _appState.initializeApp();
                    } else if (value == 'reset') {
                      _appState.resetModel();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'retry',
                        child: Row(
                          children: [
                            const Icon(Icons.refresh),
                            const SizedBox(width: 8),
                            Text(
                              _appState.isGlobalLoading
                                  ? 'Initializing...'
                                  : 'Retry Initialization',
                            ),
                          ],
                        ),
                      ),
                      if (_appState.globalError != null)
                        PopupMenuItem<String>(
                          value: 'reset',
                          child: const Row(
                            children: [
                              Icon(Icons.restore),
                              SizedBox(width: 8),
                              Text('Reset Model'),
                            ],
                          ),
                        ),
                    ];
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _isSearching
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search chats...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    try {
                                      setState(() {
                                        _isSearching = false;
                                        _searchController.clear();
                                        _filteredChats = List.from(_chats);
                                      });
                                    } catch (e) {
                                      print('Error clearing search: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to clear search: ${e.toString()}'),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              onChanged: _filterChats,
                            )
                          : InkWell(
                              onTap: () {
                                try {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                } catch (e) {
                                  print('Error enabling search: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to enable search: ${e.toString()}'),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search chats...',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    if (!_isSearching)
                      IconButton(
                        icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                        onPressed: () {
                          try {
                            setState(() {
                              _isAscending = !_isAscending;
                              _sortChats();
                            });
                          } catch (e) {
                            print('Error changing sort order: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to change sort order: ${e.toString()}'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        tooltip: _isAscending ? 'Sort Oldest First' : 'Sort Newest First',
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredChats.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No chats yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to start a new chat',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Icon(Icons.chat, color: Theme.of(context).primaryColor),
                              ),
                              title: Text(
                                chat['title']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat['lastMessage']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (chat['hasDocuments'] == true)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.attach_file, size: 14, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            'Has documents',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                _formatDate(chat['date']),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () {
                                try {
                                  final String id = chat['id'] as String;
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(chatId: id),
                                        ),
                                      )
                                      .then((_) {
                                        _loadChats();
                                        // Refresh the filtered list to maintain search state
                                        if (_searchController.text.isNotEmpty) {
                                          _filterChats(_searchController.text);
                                        }
                                      })
                                      .catchError((e) {
                                        print('Error navigating to chat: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to open chat: ${e.toString()}'),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      });
                                } catch (e) {
                                  print('Error opening chat: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to open chat: ${e.toString()}'),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () => _showActions(index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              try {
                final String newId = DateTime.now().millisecondsSinceEpoch.toString();
                setState(() {
                  _chats.insert(0, {
                    'id': newId,
                    'title': 'New Chat',
                    'lastMessage': 'No messages yet',
                    'date': DateTime.now().toIso8601String(),
                    'hasDocuments': false,
                  });
                });
                _saveChats()
                    .then((_) {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) => ChatScreen(chatId: newId)))
                          .then((_) {
                            _loadChats();
                            // Refresh the filtered list to maintain search state
                            if (_searchController.text.isNotEmpty) {
                              _filterChats(_searchController.text);
                            }
                          });
                    })
                    .catchError((e) {
                      print('Error saving new chat: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create new chat: ${e.toString()}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    });
              } catch (e) {
                print('Error creating new chat: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create new chat: ${e.toString()}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            tooltip: 'New Chat',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
