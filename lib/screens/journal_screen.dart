// lib/screens/journal_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../utils/date_formatter.dart';

class JournalScreen extends StatefulWidget {
  final bool isGuest;
  final String? userId; // Pass this down from your Auth state

  const JournalScreen({Key? key, required this.isGuest, this.userId}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false)
          .loadEntries(widget.isGuest, widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JournalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Journal"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), // Increased height for search + filter chip
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: provider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Favorites'),
                      selected: provider.showOnlyFavorites,
                      avatar: Icon(
                        provider.showOnlyFavorites ? Icons.star : Icons.star_border,
                        size: 18,
                        color: provider.showOnlyFavorites ? Colors.amber : Colors.grey,
                      ),
                      onSelected: (bool selected) {
                        provider.toggleFavoritesFilter();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.entries.isEmpty
              ? const Center(child: Text("No entries found. Tap '+' to write."))
              : ListView.builder(
                  itemCount: provider.entries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.entries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(
                          entry.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              entry.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              JournalUtils.formatDate(entry.date),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            entry.isFavorite ? Icons.star : Icons.star_border,
                            color: entry.isFavorite ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => provider.toggleFavorite(
                              entry, widget.isGuest, widget.userId),
                        ),
                        onTap: () => _showEditorModal(context, entry: entry),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditorModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditorModal(BuildContext context, {JournalEntry? entry}) {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    final titleController = TextEditingController(text: entry?.title ?? '');
    final contentController = TextEditingController(text: entry?.content ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entry == null ? "New Entry" : "Edit Entry",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional, defaults to date)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Write your thoughts...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (entry == null) {
                    provider.addEntry(
                      title: titleController.text,
                      content: contentController.text,
                      isGuest: widget.isGuest,
                      userId: widget.userId,
                    );
                  } else {
                    final updated = entry.copyWith(
                      title: titleController.text.trim().isEmpty
                          ? JournalUtils.formatDate(entry.date)
                          : titleController.text,
                      content: contentController.text,
                    );
                    provider.updateEntry(updated, widget.isGuest, widget.userId);
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save Entry"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}