import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/journal_entry.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _localKey = 'guest_journal_entries';

  // Fetch Entries with error handling
  Future<List<JournalEntry>> getEntries(bool isGuest, String? userId) async {
    try {
      if (isGuest) {
        final prefs = await SharedPreferences.getInstance();
        final String? data = prefs.getString(_localKey);
        if (data == null) return [];
        
        List decoded = jsonDecode(data);
        return decoded.map((item) => JournalEntry.fromMap(item)).toList();
      } else {
        if (userId == null) return [];
        
        // Added a timeout so Firestore never hangs forever if offline
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('journals')
            .orderBy('date', descending: true)
            .get()
            .timeout(const Duration(seconds: 10));

        return snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc.data(), doc.id))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching journal entries: $e");
      return [];
    }
  }

  // Save / Add Entry safely
  Future<void> saveEntry(JournalEntry entry, bool isGuest, String? userId) async {
    try {
      if (isGuest) {
        final entries = await getEntries(isGuest, userId);
        entries.insert(0, entry);
        await _saveLocal(entries);
      } else {
        if (userId == null) throw Exception("User ID is null for authenticated save");
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('journals')
            .doc(entry.id)
            .set(entry.toMap())
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint("Error saving journal entry: $e");
      rethrow;
    }
  }

  // Update Entry safely
  Future<void> updateEntry(JournalEntry entry, bool isGuest, String? userId) async {
    try {
      if (isGuest) {
        final entries = await getEntries(isGuest, userId);
        final index = entries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          entries[index] = entry;
          await _saveLocal(entries);
        }
      } else {
        if (userId == null) return;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('journals')
            .doc(entry.id)
            .update(entry.toMap())
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint("Error updating journal entry: $e");
    }
  }

  // Delete Entry safely
  Future<void> deleteEntry(String entryId, bool isGuest, String? userId) async {
    try {
      if (isGuest) {
        final entries = await getEntries(isGuest, userId);
        entries.removeWhere((e) => e.id == entryId);
        await _saveLocal(entries);
      } else {
        if (userId == null) return;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('journals')
            .doc(entryId)
            .delete()
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint("Error deleting journal entry: $e");
    }
  }

  Future<void> _saveLocal(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_localKey, encoded);
  }
}