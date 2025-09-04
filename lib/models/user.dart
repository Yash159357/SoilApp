import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:soil_app/const.dart';

class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final String? phoneNumber;
  final Map<String, dynamic>? preferences;

  const User({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.phoneNumber,
    this.preferences,
  });

  factory User.fromFirebaseUser(auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
      isEmailVerified: firebaseUser.emailVerified,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return User(
      uid: doc.id,
      email: data[AppConstants.fieldEmail] as String,
      displayName: data[AppConstants.fieldDisplayName] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: (data[AppConstants.fieldCreatedAt] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      phoneNumber: data['phoneNumber'] as String?,
      preferences: data['preferences'] as Map<String, dynamic>?,
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] as String,
      email: map[AppConstants.fieldEmail] as String,
      displayName: map[AppConstants.fieldDisplayName] as String?,
      photoURL: map['photoURL'] as String?,
      createdAt: map[AppConstants.fieldCreatedAt] is Timestamp
          ? (map[AppConstants.fieldCreatedAt] as Timestamp).toDate()
          : DateTime.parse(map[AppConstants.fieldCreatedAt] as String),
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] is Timestamp
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : DateTime.parse(map['lastLoginAt'] as String))
          : null,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      phoneNumber: map['phoneNumber'] as String?,
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      AppConstants.fieldEmail: email,
      AppConstants.fieldDisplayName: displayName,
      'photoURL': photoURL,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isEmailVerified': isEmailVerified,
      'phoneNumber': phoneNumber,
      'preferences': preferences,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      AppConstants.fieldEmail: email,
      AppConstants.fieldDisplayName: displayName,
      'photoURL': photoURL,
      AppConstants.fieldCreatedAt: createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'phoneNumber': phoneNumber,
      'preferences': preferences,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
    );
  }

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      } else if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }

    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U';
  }

  String get displayNameOrEmail {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email;
  }

  String? get firstName {
    if (displayName == null || displayName!.isEmpty) return null;

    final parts = displayName!.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : null;
  }

  String? get lastName {
    if (displayName == null || displayName!.isEmpty) return null;

    final parts = displayName!.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : null;
  }

  bool get hasCompleteProfile {
    return displayName != null &&
        displayName!.isNotEmpty &&
        isEmailVerified;
  }

  String get memberSince {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String get lastLoginFormatted {
    if (lastLoginAt == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastLoginAt!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
  }

  T getPreference<T>(String key, T defaultValue) {
    if (preferences == null || !preferences!.containsKey(key)) {
      return defaultValue;
    }

    final value = preferences![key];
    if (value is T) {
      return value;
    }

    return defaultValue;
  }

  User setPreference(String key, dynamic value) {
    final newPreferences = Map<String, dynamic>.from(preferences ?? {});
    newPreferences[key] = value;

    return copyWith(preferences: newPreferences);
  }

  User removePreference(String key) {
    if (preferences == null || !preferences!.containsKey(key)) {
      return this;
    }

    final newPreferences = Map<String, dynamic>.from(preferences!);
    newPreferences.remove(key);

    return copyWith(preferences: newPreferences.isEmpty ? null : newPreferences);
  }

  bool get isNewUser {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7;
  }

  bool get isActiveUser {
    if (lastLoginAt == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastLoginAt!);
    return difference.inDays <= 30;
  }

  String get maskedEmail {
    if (email.isEmpty) return '';

    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return email;

    final maskedUsername = '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    return '$maskedUsername@$domain';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! User) return false;

    return uid == other.uid &&
        email == other.email &&
        displayName == other.displayName &&
        photoURL == other.photoURL &&
        createdAt == other.createdAt &&
        lastLoginAt == other.lastLoginAt &&
        isEmailVerified == other.isEmailVerified &&
        phoneNumber == other.phoneNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      email,
      displayName,
      photoURL,
      createdAt,
      lastLoginAt,
      isEmailVerified,
      phoneNumber,
    );
  }

  @override
  String toString() {
    return 'User{'
        'uid: $uid, '
        'email: $email, '
        'displayName: $displayName, '
        'isEmailVerified: $isEmailVerified, '
        'createdAt: $createdAt'
        '}';
  }
}

class UserPreferences {
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String autoSync = 'auto_sync';
  static const String defaultDevice = 'default_device';
  static const String temperatureUnit = 'temperature_unit';
  static const String dataRetentionDays = 'data_retention_days';
  static const String chartType = 'chart_type';
  static const String lowMoistureThreshold = 'low_moisture_threshold';
  static const String highTemperatureThreshold = 'high_temperature_threshold';
}