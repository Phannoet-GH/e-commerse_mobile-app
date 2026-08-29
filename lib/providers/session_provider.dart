import 'package:flutter/foundation.dart';

import '../data/services/local_storage_service.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider({LocalStorageService? storage})
      : _storage = storage ?? LocalStorageService() {
    load();
  }

  final LocalStorageService _storage;

  bool _isReady = false;
  bool _isSignedIn = false;
  bool _isGuest = false;
  bool _showAuth = false;
  bool _showRegister = false;
  bool _showForgotPassword = false;

  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  bool get isReady => _isReady;
  bool get isSignedIn => _isSignedIn;
  bool get isGuest => _isGuest;
  bool get showAuth => _showAuth;
  bool get showRegister => _showRegister;
  bool get showForgotPassword => _showForgotPassword;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;

  /// True when unauthenticated, not an active guest session, and not in auth screens.
  bool get showOnboarding =>
      _isReady && !_isSignedIn && !_isGuest && !_showAuth && !_showForgotPassword;

  Future<void> load() async {
    await _storage.init();
    _isSignedIn = _storage.isSignedIn;
    _userName = _storage.userName;
    _userEmail = _storage.userEmail;
    _userPhone = _storage.userPhone;
    _isGuest = false;

    _isReady = true;
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    _isGuest = true;
    _showAuth = false;
    _showRegister = false;
    _showForgotPassword = false;
    notifyListeners();
  }

  void showAppTour() {
    _isGuest = false;
    _showAuth = false;
    _showRegister = false;
    _showForgotPassword = false;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _isSignedIn = false;
    _isGuest = false;
    _showAuth = false;
    _showRegister = false;
    _showForgotPassword = false;
    await _storage.setSignedIn(false);
    notifyListeners();
  }

  Future<void> openSignIn() async {
    _showAuth = true;
    _showRegister = false;
    _showForgotPassword = false;
    notifyListeners();
  }

  void openRegister() {
    _showAuth = true;
    _showRegister = true;
    _showForgotPassword = false;
    notifyListeners();
  }

  void openForgotPassword() {
    _showAuth = true;
    _showRegister = false;
    _showForgotPassword = true;
    notifyListeners();
  }

  void backToSignIn() {
    _showRegister = false;
    _showForgotPassword = false;
    _showAuth = true;
    notifyListeners();
  }

  Future<void> completeSignIn({String? email, String? name}) async {
    _isSignedIn = true;
    _isGuest = false;
    _showAuth = false;
    _showRegister = false;
    _showForgotPassword = false;
    if (email != null && email.isNotEmpty) _userEmail = email;
    if (name != null && name.isNotEmpty) _userName = name;
    await _storage.setUserProfile(name: _userName, email: _userEmail);
    await _storage.setSignedIn(true);
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _userName = name;
    _userEmail = email;
    if (phone != null && phone.isNotEmpty) _userPhone = phone;
    await _storage.setUserProfile(name: _userName, email: _userEmail, phone: _userPhone);
    await completeSignIn(email: email, name: name);
  }

  Future<void> signInWithSocial({
    required String provider,
    String? email,
    String? name,
  }) async {
    final resolvedName = name ?? (provider == 'google' ? 'Google Member' : 'Facebook Member');
    final resolvedEmail = email ?? (provider == 'google' ? 'google.user@example.com' : 'facebook.user@example.com');
    await completeSignIn(email: resolvedEmail, name: resolvedName);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    _userName = name;
    _userEmail = email;
    if (phone != null && phone.isNotEmpty) _userPhone = phone;
    await _storage.setUserProfile(name: name, email: email, phone: phone);
    notifyListeners();
  }

  Future<void> signOut() async {
    _isSignedIn = false;
    _isGuest = false;
    _showAuth = false;
    _showRegister = false;
    _showForgotPassword = false;
    await _storage.setSignedIn(false);
    notifyListeners();
  }
}
