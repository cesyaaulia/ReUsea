import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/utils/theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _facultyController;

  Uint8List? _imageBytes; // Menampung data foto baru dalam bentuk byte
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    String currentName = user?.displayName ?? (user?.email?.split('@')[0] ?? 'Budi Santoso');
    String currentEmail = user?.email ?? 'budi.21001@mhs.unesa.ac.id';

    _nameController = TextEditingController(text: currentName);
    _emailController = TextEditingController(text: currentEmail);
    _facultyController = TextEditingController();

    if (user != null) {
      _firestore.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          var data = doc.data() as Map<String, dynamic>;
          setState(() {
            _facultyController.text = data['faculty'] ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil foto dari galeri HP / Browser
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        var bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil foto: $e", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Fungsi utama menyimpan perubahan ke Auth dan Firestore (Sync Live)
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nama tidak boleh kosong!", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.sunsetOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Update nama tampilan di Firebase Auth
        await user.updateDisplayName(_nameController.text.trim());

        String downloadUrl = user.photoURL ?? '';

        // 2. Upload foto baru jika ada perubahan
        if (_imageBytes != null) {
          final storageRef = _storage.ref().child('user_photos/${user.uid}.jpg');
          final uploadTask = storageRef.putData(
            _imageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
          await user.updatePhotoURL(downloadUrl);
        }

        // 3. Update data di Firestore agar sinkron dengan yang lain
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'photoUrl': downloadUrl,
          'email': user.email,
          'faculty': _facultyController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 4. Update data seller pada chat rooms
        final chatRoomsBuyerQuery = await _firestore
            .collection('chats')
            .where('buyerId', isEqualTo: user.uid)
            .get();
        for (var doc in chatRoomsBuyerQuery.docs) {
          await doc.reference.update({
            'buyerName': _nameController.text.trim(),
            'buyerPhoto': downloadUrl,
          });
        }

        final chatRoomsSellerQuery = await _firestore
            .collection('chats')
            .where('sellerId', isEqualTo: user.uid)
            .get();
        for (var doc in chatRoomsSellerQuery.docs) {
          await doc.reference.update({
            'sellerName': _nameController.text.trim(),
            'sellerPhoto': downloadUrl,
          });
        }

        // 5. Update data seller pada barang jualan yang aktif
        final productsQuery = await _firestore
            .collection('products')
            .where('sellerId', isEqualTo: user.uid)
            .get();
        for (var doc in productsQuery.docs) {
          await doc.reference.update({
            'sellerName': _nameController.text.trim(),
            'sellerPhoto': downloadUrl,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profil berhasil diperbarui!", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.ecoTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          );
          Navigator.pop(context); // Kembali ke halaman Profile
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      body: OceanGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button & title Row
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.softShadow(),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppTheme.darkNavy,
                            size: 18,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.lexend(
                          color: AppTheme.darkNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Profile Picture Section
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.oceanWaveGradient,
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: SizedBox(
                                width: 104,
                                height: 104,
                                child: _imageBytes != null
                                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                    : (currentUser?.photoURL != null
                                        ? Image.network(currentUser!.photoURL!, fit: BoxFit.cover)
                                        : const Icon(Icons.person_rounded, size: 54, color: AppTheme.secondaryBlue)),
                              ),
                            ),
                          ),
                        ),
                        // Floating camera badge
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Text(
                      'Ubah Foto Profil',
                      style: GoogleFonts.lexend(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  _buildInputField(
                    label: "NAMA LENGKAP",
                    controller: _nameController,
                    hint: "Masukkan nama lengkap Anda",
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: "FAKULTAS / JURUSAN",
                    controller: _facultyController,
                    hint: "Contoh: Fakultas Teknik / S1 Informatika",
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    label: "ALAMAT EMAIL (Terkunci)",
                    controller: _emailController,
                    hint: "",
                    readOnly: true,
                  ),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppTheme.lightBlueGrey.withValues(alpha: 0.4), width: 1.5),
                        ),
                      ),
                      child: Text(
                        'Batalkan',
                        style: GoogleFonts.lexend(
                          color: AppTheme.secondaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.secondaryBlue,
              letterSpacing: 1.0,
            ),
          ),
        ),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: readOnly ? AppTheme.secondaryBlue : AppTheme.darkNavy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lexend(color: AppTheme.lightBlueGrey, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: readOnly ? AppTheme.bgLight.withValues(alpha: 0.5) : Colors.white,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: readOnly ? Colors.transparent : AppTheme.primaryBlue,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: readOnly ? Colors.transparent : AppTheme.primaryBlue.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
