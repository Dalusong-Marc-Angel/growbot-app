// lib/services/crop_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_crop_model.dart';

class CropService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addCrop(UserCrop crop) async {
    if (_userId == null) throw Exception('No authenticated user');
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('crops')
        .add(crop.toMap());
  }

  Stream<List<UserCrop>> getUserCropsStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('crops')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserCrop.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateCrop(UserCrop crop) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('crops')
        .doc(crop.id)
        .update(crop.toMap());
  }

  Future<void> deleteCrop(String cropId) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('crops')
        .doc(cropId)
        .delete();
  }
}