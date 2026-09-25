// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? postToEdit; // If passed, we are editing

  const CreatePostScreen({super.key, this.postToEdit});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final TextEditingController _contentController;
  String _category = 'Tip & Trick';
  
  // Fixed: Changed 'Tip & Trust' to 'Tip & Trick' to match the default value and community filter
  final List<String> _categories = ['Tip & Trick', 'Question', 'General'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.postToEdit?.content ?? '');
    if (widget.postToEdit != null && _categories.contains(widget.postToEdit!.category)) {
      _category = widget.postToEdit!.category;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _savePost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (widget.postToEdit == null) {
        // Create new post
        await FirebaseFirestore.instance.collection('posts').add({
          'userId': user?.uid ?? 'anonymous',
          'userName': user?.displayName ?? user?.email?.split('@')[0] ?? 'Grower',
          'content': _contentController.text.trim(),
          'imageUrl': '', 
          'category': _category,
          'likes': [],
          'commentCount': 0,
          'createdAt': Timestamp.now(),
        });
      } else {
        // Update existing post
        await FirebaseFirestore.instance.collection('posts').doc(widget.postToEdit!.id).update({
          'content': _contentController.text.trim(),
          'category': _category,
        });
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving post: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Post' : 'New Publication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share a tip, trick, or ask the community a question...',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePost,
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : Text(isEditing ? 'Save Changes' : 'Post to Community'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}