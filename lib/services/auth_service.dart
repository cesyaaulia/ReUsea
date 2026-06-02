import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan data user yang sedang login saat ini
  User? get currentUser => _auth.currentUser;

  // Stream untuk memantau perubahan status login secara real-time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. REGISTER dengan Validasi Domain Email UNESA
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    // Validasi lokal sebelum menembak server Firebase
    if (!email.endsWith('@mhs.unesa.ac.id')) {
      onError(
        'Pendaftaran gagal! Wajib menggunakan email mahasiswa UNESA (@mhs.unesa.ac.id).',
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Otomatis kirim tautan verifikasi ke email UNESA tersebut
      await userCredential.user?.sendEmailVerification();
      onSuccess();
    } on FirebaseAuthException catch (e) {
      onError(_handleAuthError(e));
    } catch (e) {
      onError('Terjadi kesalahan: $e');
    }
  }

  // 2. LOGIN
  Future<void> loginWithEmail({
    required String email,
    required String password,
    required Function(User user) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        onSuccess(user);
      }
    } on FirebaseAuthException catch (e) {
      onError(_handleAuthError(e));
    } catch (e) {
      onError('Terjadi kesalahan: $e');
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw 'Gagal mengirim email reset: ${e.toString()}';
    }
  }

  // 3. CEK STATUS VERIFIKASI EMAIL (Untuk Halaman Tunggu OTP)
  Future<bool> checkEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user
          .reload(); // Memaksa Firebase memperbarui data terbaru dari server
      user = _auth.currentUser; // Ambil instansiasi user terbaru
      return user?.emailVerified ?? false;
    }
    return false;
  }

  // 4. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Helper untuk menerjemahkan kode error Firebase ke Bahasa Indonesia yang ramah
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah! Minimal terdiri dari 6 karakter.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan langsung login.';
      case 'invalid-email':
        return 'Format penulisan email salah.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan register terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan periksa kembali.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}
