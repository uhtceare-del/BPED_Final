import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../config/local_config.dart';
import '../models/user_model.dart';
import '../core/auth_guard.dart';
import '../services/auth_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
export '../core/auth_guard.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

enum AuthBootstrapStatus {
  signedOut,
  loadingProfile,
  onboardingRequired,
  ready,
}

class AuthBootstrapState {
  final AuthBootstrapStatus status;
  final AppUser? appUser;

  const AuthBootstrapState._(this.status, this.appUser);

  const AuthBootstrapState.signedOut()
    : this._(AuthBootstrapStatus.signedOut, null);

  const AuthBootstrapState.loadingProfile()
    : this._(AuthBootstrapStatus.loadingProfile, null);

  const AuthBootstrapState.onboardingRequired([AppUser? appUser])
    : this._(AuthBootstrapStatus.onboardingRequired, appUser);

  const AuthBootstrapState.ready(AppUser appUser)
    : this._(AuthBootstrapStatus.ready, appUser);
}

Future<void> _ensureBootstrapUserDoc(
  FirebaseFirestore firestore,
  User authUser,
) async {
  final userDocRef = firestore.collection('users').doc(authUser.uid);
  final docSnapshot = await userDocRef.get();
  if (docSnapshot.exists) {
    return;
  }

  await userDocRef.set({
    'email': authUser.email ?? '',
    'fullName': authUser.displayName ?? (authUser.email?.split('@')[0] ?? ''),
    'role': '',
    'avatarUrl': authUser.photoURL ?? '',
    'yearLevel': '',
    'section': '',
    'onboardingCompleted': false,
    'createdAt': FieldValue.serverTimestamp(),
    'isDeleted': false,
    'isDisabled': false,
  });
}

bool _isConfiguredAdminEmail(String? email) {
  final normalizedAdminEmail = LocalConfig.adminEmail.trim().toLowerCase();
  final normalizedEmail = email?.trim().toLowerCase() ?? '';
  return normalizedAdminEmail.isNotEmpty &&
      normalizedEmail == normalizedAdminEmail;
}

Future<void> _syncConfiguredAdminProfile(
  FirebaseFirestore firestore,
  User authUser,
) async {
  if (!_isConfiguredAdminEmail(authUser.email)) {
    return;
  }

  final payload = <String, dynamic>{
    'email': authUser.email ?? LocalConfig.adminEmail,
    'role': 'admin',
    'onboardingCompleted': true,
    'isDeleted': false,
    'isDisabled': false,
  };

  final displayName = authUser.displayName?.trim() ?? '';
  if (displayName.isNotEmpty) {
    payload['fullName'] = displayName;
  }

  final photoUrl = authUser.photoURL?.trim() ?? '';
  if (photoUrl.isNotEmpty) {
    payload['avatarUrl'] = photoUrl;
  }

  await firestore
      .collection('users')
      .doc(authUser.uid)
      .set(payload, SetOptions(merge: true));
}

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  if (ref.watch(signOutInProgressProvider)) {
    return Stream.value(null);
  }

  final authState = ref.watch(authStateProvider);
  final stream = authState.when(
    data: (authUser) {
      if (authUser == null) {
        return Stream.value(null);
      }

      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(authUser.uid)
          .snapshots()
          .map(
            (snap) => snap.exists
                ? AppUser.fromFirestore(snap.data()!, authUser.uid)
                : null,
          );
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );

  return guardAuthTransitionStream(ref, stream, fallbackValue: null);
});

final authBootstrapProvider = StreamProvider<AuthBootstrapState>((ref) async* {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);

  yield* auth.authStateChanges().asyncExpand((authUser) async* {
    if (authUser == null) {
      yield const AuthBootstrapState.signedOut();
      return;
    }

    yield const AuthBootstrapState.loadingProfile();
    final bootstrapReady = await guardAuthTransitionFuture(ref, () async {
      await _ensureBootstrapUserDoc(firestore, authUser);
      await _syncConfiguredAdminProfile(firestore, authUser);
      return true;
    }, fallbackValue: false);
    if (!bootstrapReady) {
      yield const AuthBootstrapState.signedOut();
      return;
    }

    final profileStream = firestore
        .collection('users')
        .doc(authUser.uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) {
            return const AuthBootstrapState.loadingProfile();
          }

          final data = snap.data();
          if (data == null) {
            return const AuthBootstrapState.loadingProfile();
          }

          final appUser = AppUser.fromFirestore(data, authUser.uid);
          final role = appUser.role.trim().toLowerCase();
          final onboardingCompleted = data['onboardingCompleted'] == true;

          if (role.isEmpty || !onboardingCompleted) {
            return AuthBootstrapState.onboardingRequired(appUser);
          }

          return AuthBootstrapState.ready(appUser);
        });

    yield* guardAuthTransitionStream(
      ref,
      profileStream,
      fallbackValue: const AuthBootstrapState.signedOut(),
    );
  });
});

final bootstrapAppUserProvider = Provider<AppUser?>((ref) {
  final bootstrapState = ref.watch(authBootstrapProvider).valueOrNull;
  if (bootstrapState?.status != AuthBootstrapStatus.ready) {
    return null;
  }
  return bootstrapState?.appUser;
});

final bootstrapProfileReadyProvider = Provider<bool>((ref) {
  return ref.watch(bootstrapAppUserProvider) != null;
});

// ── Result types ──────────────────────────────────────────────────────────────

enum GoogleSignInResult { existingUser, newUser, cancelled, error }

/// Structured auth error — gives the UI a code to map to a user-friendly message
/// without leaking Firebase internals.
enum AuthErrorCode {
  invalidEmail,
  invalidEmailDomain,
  emailInUse,
  weakPassword,
  wrongPassword,
  userNotFound,
  tooManyRequests,
  networkError,
  unknown,
}

class AuthException implements Exception {
  final AuthErrorCode code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

// ── Email validation service ───────────────────────────────────────────────────

class EmailValidationService {
  static const _apiKey = '';
  static const _endpoint = 'https://emailvalidation.abstractapi.com/v1/';
  static const _minQualityScore = 0.5;

  static Future<AuthException?> validate(String email) async {
    if (_apiKey.isEmpty) {
      debugPrint('[EmailValidation] No API key — skipping.');
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_endpoint?api_key=$_apiKey&email=${Uri.encodeComponent(email)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('[EmailValidation] HTTP ${response.statusCode} — skipping.');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final deliverability =
          data['email_deliverability'] as Map<String, dynamic>? ?? {};
      final status = (deliverability['status'] as String? ?? 'unknown')
          .toLowerCase();
      final isFormatValid = deliverability['is_format_valid'] as bool? ?? true;
      final isMxValid = deliverability['is_mx_valid'] as bool? ?? true;

      if (!isFormatValid) {
        return const AuthException(
          AuthErrorCode.invalidEmail,
          'Please enter a valid email address.',
        );
      }
      if (!isMxValid || status == 'undeliverable') {
        return const AuthException(
          AuthErrorCode.invalidEmailDomain,
          'This email address cannot receive mail. Please check and try again.',
        );
      }

      final quality = data['email_quality'] as Map<String, dynamic>? ?? {};
      final qualityScore = (quality['score'] as num?)?.toDouble() ?? 1.0;
      final isDisposable = quality['is_disposable'] as bool? ?? false;

      if (isDisposable) {
        return const AuthException(
          AuthErrorCode.invalidEmailDomain,
          'Disposable email addresses are not allowed. Please use a permanent address.',
        );
      }
      if (qualityScore < _minQualityScore) {
        return const AuthException(
          AuthErrorCode.invalidEmailDomain,
          'This email address appears invalid. Please use a different address.',
        );
      }

      final risk = data['email_risk'] as Map<String, dynamic>? ?? {};
      final addressRisk = (risk['address_risk_status'] as String? ?? 'low')
          .toLowerCase();

      if (addressRisk == 'high') {
        return const AuthException(
          AuthErrorCode.invalidEmailDomain,
          'This email address has been flagged as high risk. Please use a different address.',
        );
      }

      return null;
    } catch (e) {
      debugPrint('[EmailValidation] Exception: $e — allowing sign-up.');
      return null;
    }
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository(this.auth, this.firestore);

  Future<GoogleSignInResult> signInWithGoogleAndCheck() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        credential = await auth.signInWithPopup(googleProvider);
      } else {
        final gsi = GoogleSignIn.instance;
        await gsi.signOut();
        final googleUser = await gsi.authenticate();
        final googleAuth = googleUser.authentication;
        if (googleAuth.idToken == null) return GoogleSignInResult.error;
        final oauthCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        credential = await auth.signInWithCredential(oauthCredential);
      }

      final uid = credential.user?.uid;
      if (uid == null) return GoogleSignInResult.error;

      await _ensureBootstrapUserDoc(firestore, credential.user!);
      await _syncConfiguredAdminProfile(firestore, credential.user!);

      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final isComplete =
          doc.exists &&
          (data?['onboardingCompleted'] == true) &&
          ((data?['role'] as String?)?.isNotEmpty ?? false);

      return isComplete
          ? GoogleSignInResult.existingUser
          : GoogleSignInResult.newUser;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInResult.cancelled;
      }
      debugPrint('[Google SignIn] ${e.code} — ${e.description}');
      return GoogleSignInResult.error;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return GoogleSignInResult.cancelled;
      }
      debugPrint('[FirebaseAuth] ${e.code} — ${e.message}');
      return GoogleSignInResult.error;
    } catch (e) {
      debugPrint('[Unexpected GoogleSignIn] $e');
      return GoogleSignInResult.error;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureBootstrapUserDoc(firestore, cred.user!);
      await _syncConfiguredAdminProfile(firestore, cred.user!);

      await _ensureUserIsActive(cred);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseSignInError(e);
    } catch (e) {
      throw AuthException(
        AuthErrorCode.unknown,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String section,
    required String yearLevel,
    String? avatarUrl,
    String? fullName,
  }) async {
    final validationError = await EmailValidationService.validate(email);
    if (validationError != null) throw validationError;

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await firestore.collection('users').doc(cred.user!.uid).set({
        'fullName': fullName ?? email.split('@')[0],
        'email': email,
        'role': role == 'student' ? '' : role,
        'avatarUrl': avatarUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'section': role == 'student' ? '' : section,
        'yearLevel': role == 'student' ? '' : yearLevel,
        'onboardingCompleted': role == 'student' ? false : true,
        'isDeleted': false,
        'isDisabled': false,
      });

      return cred;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseSignUpError(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        AuthErrorCode.unknown,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> completeOnboarding({
    required String uid,
    required String fullName,
    required String role,
    required String yearLevel,
    required String section,
  }) async {
    final user = auth.currentUser;
    await firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': user?.email,
      'role': role,
      'avatarUrl': user?.photoURL ?? '',
      'yearLevel': yearLevel,
      'section': section,
      'onboardingCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'isDisabled': false,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
  }) => firestore.collection('users').doc(uid).update({'avatarUrl': avatarUrl});

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String avatarUrl,
  }) async {
    await firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'avatarUrl': avatarUrl,
    });
  }

  Future<void> signOut() async {
    try {
      final signOutSettled = auth
          .authStateChanges()
          .firstWhere((user) => user == null)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (!kIsWeb) await GoogleSignIn.instance.signOut();
      await auth.signOut();
      await signOutSettled;
    } catch (e) {
      debugPrint('[SignOut] $e');
    }
  }

  Future<void> _ensureUserIsActive(UserCredential cred) async {
    final user = cred.user;
    if (user == null) return;

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.data()?['isDisabled'] == true) {
      await signOut();
      throw const AuthException(
        AuthErrorCode.unknown,
        'This account has been disabled. Please contact an administrator.',
      );
    }
    if (userDoc.data()?['isDeleted'] == true) {
      await signOut();
      throw const AuthException(
        AuthErrorCode.unknown,
        'This account has been deleted and moved to trash. Please contact an administrator.',
      );
    }
  }

  AuthException _mapFirebaseSignInError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return const AuthException(
          AuthErrorCode.userNotFound,
          'No account found with that email and password combination.',
        );
      case 'wrong-password':
        return const AuthException(
          AuthErrorCode.wrongPassword,
          'Incorrect password. Please try again.',
        );
      case 'invalid-email':
        return const AuthException(
          AuthErrorCode.invalidEmail,
          'Please enter a valid email address.',
        );
      case 'user-disabled':
        return const AuthException(
          AuthErrorCode.unknown,
          'This account has been disabled. Please contact support.',
        );
      case 'too-many-requests':
        return const AuthException(
          AuthErrorCode.tooManyRequests,
          'Too many failed attempts. Please wait a moment and try again.',
        );
      case 'network-request-failed':
        return const AuthException(
          AuthErrorCode.networkError,
          'No internet connection. Please check your network and try again.',
        );
      default:
        debugPrint('[FirebaseAuth SignIn] Unhandled code: ${e.code}');
        return AuthException(
          AuthErrorCode.unknown,
          'Login failed. Please try again.',
        );
    }
  }

  AuthException _mapFirebaseSignUpError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const AuthException(
          AuthErrorCode.emailInUse,
          'An account with that email already exists. Try signing in instead.',
        );
      case 'invalid-email':
        return const AuthException(
          AuthErrorCode.invalidEmail,
          'Please enter a valid email address.',
        );
      case 'weak-password':
        return const AuthException(
          AuthErrorCode.weakPassword,
          'Password is too weak. Please use at least 6 characters.',
        );
      case 'operation-not-allowed':
        return const AuthException(
          AuthErrorCode.unknown,
          'Email sign-up is not enabled. Please contact support.',
        );
      case 'network-request-failed':
        return const AuthException(
          AuthErrorCode.networkError,
          'No internet connection. Please check your network and try again.',
        );
      default:
        debugPrint('[FirebaseAuth SignUp] Unhandled code: ${e.code}');
        return AuthException(
          AuthErrorCode.unknown,
          'Sign-up failed. Please try again.',
        );
    }
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class AuthController {
  final Ref ref;
  final AuthRepository repository;
  AuthController(this.ref, this.repository);

  Future<GoogleSignInResult> signInWithGoogleAndCheck() =>
      repository.signInWithGoogleAndCheck();

  Future<UserCredential> signIn(String email, String password) =>
      repository.signIn(email, password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String section,
    required String yearLevel,
    String? avatarUrl,
    String? fullName,
  }) => repository.signUp(
    email: email,
    password: password,
    role: role,
    section: section,
    yearLevel: yearLevel,
    avatarUrl: avatarUrl,
    fullName: fullName,
  );

  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
  }) => repository.updateUserAvatar(uid: uid, avatarUrl: avatarUrl);

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String avatarUrl,
  }) => repository.updateUserProfile(
    uid: uid,
    fullName: fullName,
    avatarUrl: avatarUrl,
  );

  Future<void> signOut() async {
    ref.read(signOutInProgressProvider.notifier).state = true;
    try {
      await repository.signOut();
      await Future<void>.delayed(Duration.zero);
      ref.invalidate(currentUserProvider);
      ref.invalidate(authBootstrapProvider);
      ref.invalidate(userRoleProvider);
    } finally {
      ref.read(signOutInProgressProvider.notifier).state = false;
    }
  }

  User? get currentUser => repository.auth.currentUser;
}

// ── Final Providers ───────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref, ref.watch(authRepositoryProvider));
});

final userRoleProvider = FutureProvider<String>((ref) async {
  if (ref.watch(signOutInProgressProvider)) return '';

  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return '';

  return guardAuthTransitionFuture(ref, () async {
    await _ensureBootstrapUserDoc(ref.watch(firestoreProvider), user);
    final doc = await ref
        .watch(firestoreProvider)
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['role'] as String? ?? '';
  }, fallbackValue: '');
});
