import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      serverClientId: '231987321719-urk2lgqp7jqkcvqu6qso7ipcse3darhd.apps.googleusercontent.com',
    );

    _isInitialized = true;
  }

  Future<String?> getGoogleIdToken() async {
    await _initialize();

    final account = await _googleSignIn.authenticate();

    final auth = account.authentication;

    return auth.idToken;
  }
}