import 'package:flutter/foundation.dart';

import '../data/services/local_storage_service.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider({LocalStorageService? storage})
      : _storage = storage ?? LocalStorageService() {
    load();
  }

  final LocalStorageService _storage;

  bool _isReady = false;
  bool _hasOpenedBefore = false;
  bool _isSignedIn = false;
  bool _showFirstLaunchOnboarding = false;
  bool _showAuth = false;
  bool _showRegister = false;

  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  bool get isReady => _isReady;
  bool get isSignedIn => _isSignedIn;
  bool get showAuth => _showAuth;
  bool get showRegister => _showRegister;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;

  bool get showOnboarding =>
      _isReady && _showFirstLaunchOnboarding && !_isSignedIn && !_showAuth;

  Future<void> load() async {
    await _storage.init();
    _hasOpenedBefore = _storage.hasOpenedBefore;
    _isSignedIn = _storage.isSignedIn;
    _userName = _storage.userName;
    _userEmail = _storage.userEmail;
    _userPhone = _storage.userPhone;

    if (!_hasOpenedBefore && !_isSignedIn) {
      _showFirstLaunchOnboarding = true;
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> _markOpened() async {
    _hasOpenedBefore = true;
    await _storage.setHasOpenedBefore(true);
  }

  Future<void> resetOnboarding() async {
    _hasOpenedBefore = false;
    _showFirstLaunchOnboarding = true;
    _showAuth = false;
    _showRegister = false;
    await _storage.setHasOpenedBefore(false);
    notifyListeners();
  }

  void showAppTour() {
    _showFirstLaunchOnboarding = true;
    _showAuth = false;
    _showRegister = false;
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    await _markOpened();
    _showFirstLaunchOnboarding = false;
    _showAuth = false;
    _showRegister = false;
    notifyListeners();
  }

  Future<void> openSignIn() async {
    await _markOpened();
    _showFirstLaunchOnboarding = false;
    _showAuth = true;
    _showRegister = false;
    notifyListeners();
  }

  void openRegister() {
    _showAuth = true;
    _showRegister = true;
    notifyListeners();
  }

  void backToSignIn() {
    _showRegister = false;
    notifyListeners();
  }

  Future<void> completeSignIn({String? email, String? name}) async {
    await _markOpened();
    _isSignedIn = true;
    _showAuth = false;
    _showRegister = false;
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
    _showAuth = true;
    _showRegister = false;
    await _storage.setSignedIn(false);
    notifyListeners();
  }
}
