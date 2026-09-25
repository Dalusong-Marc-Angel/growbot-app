// lib/screens/ai_chat_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    
  );

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  XFile? _selectedImage;

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'text': 'Hello how can i help you?',
      'imagePath': null,
    }
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-3.6-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are an expert agricultural and home gardening assistant tailored specifically for the Philippines.\n'
        'Guidelines:\n'
        '- Factor in PH wet (Tag-ulan) and dry (Tag-init) seasons, heat humidity, and monsoon drainage.\n'
        '- Reference common local soil conditions (e.g., clay loam, volcanic soil, alluvial soil).\n'
        '- Use familiar local plant names alongside common English names (e.g., Talong, Sitaw, Kalabasa, Kangkong, Ampalaya, Siling Labuyo).\n'
        '- Suggest locally available organic materials (e.g., CRH, vermicompost, coco coir, manure).\n'
        '- PHOTO ANALYSIS: When provided an image of a space or plot, evaluate sunlight, drainage potential, and available area to recommend whether Flower Pots/Containers or Garden Beds/Raised Beds are better suited.\n'
        '- CROP IDENTIFICATION & HEALTH: When shown a plant photo, identify the crop species and inspect leaves/stem for signs of diseases, deficiency, or pest damage.',
      ),
    );

    _chatSession = _model.startChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture/select image: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final imageToUpload = _selectedImage;

    if ((text.isEmpty && imageToUpload == null) || _isLoading) return;

    _controller.clear();
    setState(() {
      _selectedImage = null;
      _messages.add({
        'sender': 'user',
        'text': text.isNotEmpty ? text : 'Please analyze this photo for me.',
        'imagePath': imageToUpload?.path,
      });
      _messages.add({'sender': 'ai', 'text': '', 'imagePath': null});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final List<Part> parts = [];

      if (imageToUpload != null) {
        final Uint8List imageBytes = await imageToUpload.readAsBytes();
        final mimeType = imageToUpload.mimeType ?? 'image/jpeg';
        parts.add(DataPart(mimeType, imageBytes));
      }

      final promptText = text.isNotEmpty
          ? text
          : 'Please inspect this photo. If it shows a garden space, advise if pots or raised beds are better. If it shows a plant, identify the crop and check for health issues.';

      parts.add(TextPart(promptText));

      final responseStream = _chatSession.sendMessageStream(Content.multi(parts));

      await for (final chunk in responseStream) {
        final chunkText = chunk.text;
        if (chunkText != null) {
          setState(() {
            _messages.last['text'] = (_messages.last['text'] ?? '') + chunkText;
          });
          _scrollToBottom();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('--- GEMINI API ERROR ---');
      debugPrint('$e');
      debugPrint('$stackTrace');
      
      setState(() {
        _messages.last['text'] = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gardening Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _chatSession = _model.startChat();
                _messages.clear();
                _messages.add({
                  'sender': 'ai',
                  'text': 'Conversation reset. What can I help you grow today?',
                  'imagePath': null,
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                final text = msg['text'] as String;
                final imagePath = msg['imagePath'] as String?;

                if (!isUser && text.isEmpty && _isLoading && index == _messages.length - 1) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imagePath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(imagePath, height: 180, fit: BoxFit.cover)
                                : Image.file(File(imagePath), height: 180, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (text.isNotEmpty)
                          Text(
                            text,
                            style: TextStyle(
                              color: isUser
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerLow,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(_selectedImage!.path, width: 48, height: 48, fit: BoxFit.cover)
                        : Image.file(File(_selectedImage!.path), width: 48, height: 48, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Photo attached',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedImage = null),
                  )
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Take Photo',
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  tooltip: 'Choose Image',
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Ask or describe photo...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}