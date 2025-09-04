import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:soil_app/const.dart';
import 'package:soil_app/models/soil_reading.dart';
import 'package:soil_app/models/user.dart';

/// Service class to handle all Firebase operations including Authentication and Firestore
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Auth getter
  auth.User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Authentication Methods

  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = User.fromFirebaseUser(credential.user!);
        // Update last login time in Firestore
        await updateUserLastLogin(user.uid);
        return user;
      }
      return null;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in');
    }
  }

  /// Create account with email and password
  Future<User?> createUserWithEmailAndPassword(
      String email,
      String password,
      String? displayName
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }

        final user = User.fromFirebaseUser(credential.user!);

        // Create user document in Firestore
        await createUserDocument(user);

        // Send email verification
        await credential.user!.sendEmailVerification();

        return user;
      }
      return null;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send email verification');
    }
  }

  /// Reload current user to get updated info
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user data');
    }
  }

  /// Firestore User Operations

  /// Create user document in Firestore
  Future<void> createUserDocument(User user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  /// Get user document from Firestore
  Future<User?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user document: ${e.toString()}');
    }
  }

  /// Update user document in Firestore
  Future<void> updateUserDocument(User user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user document: ${e.toString()}');
    }
  }

  /// Update user's last login time
  Future<void> updateUserLastLogin(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      // Don't throw error for login time update failure
      print('Failed to update last login time: ${e.toString()}');
    }
  }

  /// Soil Reading Operations

  /// Add a new soil reading to Firestore
  Future<String> addSoilReading(SoilReading reading) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.soilReadingsCollection)
          .add(reading.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save soil reading: ${e.toString()}');
    }
  }

  /// Get soil readings for current user
  Future<List<SoilReading>> getUserSoilReadings({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No user signed in');
      }

      Query query = _firestore
          .collection(AppConstants.soilReadingsCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .orderBy(AppConstants.fieldTimestamp, descending: true);

      // Apply date filters if provided
      if (startDate != null) {
        query = query.where(
          AppConstants.fieldTimestamp,
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          AppConstants.fieldTimestamp,
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => SoilReading.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get soil readings: ${e.toString()}');
    }
  }

  /// Get real-time stream of soil readings for current user
  Stream<List<SoilReading>> getUserSoilReadingsStream({
    int? limit,
  }) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(AppConstants.soilReadingsCollection)
        .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
        .orderBy(AppConstants.fieldTimestamp, descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => SoilReading.fromFirestore(doc)).toList(),
    );
  }

  /// Get the latest soil reading for current user
  Future<SoilReading?> getLatestSoilReading() async {
    try {
      final readings = await getUserSoilReadings(limit: 1);
      return readings.isNotEmpty ? readings.first : null;
    } catch (e) {
      throw Exception('Failed to get latest soil reading: ${e.toString()}');
    }
  }

  /// Update a soil reading
  Future<void> updateSoilReading(SoilReading reading) async {
    try {
      if (reading.id == null) {
        throw Exception('Reading ID is required for update');
      }

      await _firestore
          .collection(AppConstants.soilReadingsCollection)
          .doc(reading.id)
          .update(reading.toFirestore());
    } catch (e) {
      throw Exception('Failed to update soil reading: ${e.toString()}');
    }
  }

  /// Delete a soil reading
  Future<void> deleteSoilReading(String readingId) async {
    try {
      await _firestore
          .collection(AppConstants.soilReadingsCollection)
          .doc(readingId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete soil reading: ${e.toString()}');
    }
  }

  /// Get soil readings count for current user
  Future<int> getUserSoilReadingsCount() async {
    try {
      if (currentUserId == null) {
        return 0;
      }

      final snapshot = await _firestore
          .collection(AppConstants.soilReadingsCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Failed to get readings count: ${e.toString()}');
      return 0;
    }
  }

  /// Device Operations

  /// Save device information to Firestore
  Future<void> saveDeviceInfo(String deviceId, Map<String, dynamic> deviceData) async {
    try {
      if (currentUserId == null) {
        throw Exception('No user signed in');
      }

      await _firestore
          .collection(AppConstants.devicesCollection)
          .doc('${currentUserId}_$deviceId')
          .set({
        ...deviceData,
        AppConstants.fieldUserId: currentUserId,
        AppConstants.fieldDeviceId: deviceId,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save device info: ${e.toString()}');
    }
  }

  /// Get saved devices for current user
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      if (currentUserId == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection(AppConstants.devicesCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Failed to get user devices: ${e.toString()}');
      return [];
    }
  }

  /// Batch Operations

  /// Delete all soil readings for current user (useful for testing)
  Future<void> deleteAllUserSoilReadings() async {
    try {
      if (currentUserId == null) {
        throw Exception('No user signed in');
      }

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(AppConstants.soilReadingsCollection)
          .where(AppConstants.fieldUserId, isEqualTo: currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all soil readings: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return AppConstants.errorNetworkUnavailable;
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}