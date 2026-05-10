import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/app_exceptions.dart';
import '../core/error_handler.dart';

/// Service class for authentication operations
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Sign in with email and password
  Future<Result<UserCredential>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(credential);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Email sign in',
      );
      return Result.failure(appError);
    }
  }

  /// Sign up with email and password
  Future<Result<UserCredential>> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(credential);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Email sign up',
      );
      return Result.failure(appError);
    }
  }

  /// Sign in with Google
  Future<Result<UserCredential>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return Result.success(userCredential);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Google sign in',
      );
      return Result.failure(appError);
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return const Result.success(null);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Sign out',
      );
      return Result.failure(appError);
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Create user profile in Firestore
  Future<Result<void>> createUserProfile(
    String uid, {
    required String email,
    String? fullName,
    String? role,
    String? avatarUrl,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final userData = {
        'email': email,
        'fullName': fullName,
        'role': role ?? 'student',
        'avatarUrl': avatarUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
        'isDeleted': false,
        'isDisabled': false,
      };

      await userDoc.set(userData);
      return const Result.success(null);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Create user profile',
      );
      return Result.failure(appError);
    }
  }

  /// Update user profile
  Future<Result<void>> updateUserProfile(
    String uid, {
    String? fullName,
    String? role,
    String? avatarUrl,
    String? section,
    String? yearLevel,
    bool? onboardingCompleted,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['fullName'] = fullName;
      if (role != null) updateData['role'] = role;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
      if (section != null) updateData['section'] = section;
      if (yearLevel != null) updateData['yearLevel'] = yearLevel;
      if (onboardingCompleted != null) {
        updateData['onboardingCompleted'] = onboardingCompleted;
      }

      if (updateData.isNotEmpty) {
        await userDoc.update(updateData);
      }

      return const Result.success(null);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Update user profile',
      );
      return Result.failure(appError);
    }
  }

  /// Get user profile
  Future<Result<AppUser?>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return const Result.success(null);
      }

      final user = AppUser.fromFirestore(doc.data()!, uid);
      return Result.success(user);
    } catch (error) {
      final appError = ErrorHandler.handleFirebaseException(
        error,
        context: 'Get user profile',
      );
      return Result.failure(appError);
    }
  }

  /// Stream user profile changes
  Stream<Result<AppUser?>> streamUserProfile(String uid) async* {
    final snapshots = _firestore.collection('users').doc(uid).snapshots();

    try {
      await for (final doc in snapshots) {
        if (!doc.exists || doc.data() == null) {
          yield const Result<AppUser?>.success(null);
          continue;
        }

        try {
          final user = AppUser.fromFirestore(doc.data()!, uid);
          yield Result<AppUser?>.success(user);
        } catch (error) {
          yield Result<AppUser?>.failure(
            ErrorHandler.handleFirebaseException(
              error,
              context: 'Stream user profile',
            ),
          );
        }
      }
    } catch (error) {
      yield Result<AppUser?>.failure(
        ErrorHandler.handleFirebaseException(
          error,
          context: 'Stream user profile',
        ),
      );
    }
  }
}
