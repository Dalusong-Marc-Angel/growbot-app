class JournalEntry {
  final String id;
  String title;
  String content;
  DateTime date;
  bool isFavorite;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.isFavorite = false,
  });

  // Convert to Map for Local Storage / Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  // Create from Map (Local)
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: DateTime.parse(map['date']),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // Create from Firestore Document
  factory JournalEntry.fromFirestore(Map<String, dynamic> map, String docId) {
    return JournalEntry(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: DateTime.parse(map['date']),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  JournalEntry copyWith({
    String? title,
    String? content,
    DateTime? date,
    bool? isFavorite,
  }) {
    return JournalEntry(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}