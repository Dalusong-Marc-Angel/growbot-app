// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final String? imageUrl;
  final String category; // e.g., 'Tip & Trick', 'Question'
  final List<String> likes;
  final int commentCount;
  final Timestamp createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.imageUrl,
    required this.category,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous Grower',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'General',
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': createdAt,
    };
  }
}