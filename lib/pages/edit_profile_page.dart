import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  Uint8List? _imageBytes; // Menampung data foto baru dalam bentuk byte
  bool _isLoading = false;

  late TextEditingController _facultyController;

  @override
  void initState() {
    super.initState();
    // Mengambil data akun yang sedang login saat ini
    final user = _auth.currentUser;
    String currentName =
        user?.displayName ?? (user?.email?.split('@')[0] ?? 'Budi Santoso');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengambil foto: $e")));
      }
    }
  }

  // Fungsi utama menyimpan perubahan ke Auth dan Firestore (Sync Live)
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nama tidak boleh kosong!"),
          backgroundColor: Colors.orangeAccent,
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

        // 2. Jika user memilih foto baru, upload ke Firebase Storage
        if (_imageBytes != null) {
          Reference ref = _storage
              .ref()
              .child('profile_pictures')
              .child('${user.uid}.jpg');
          await ref.putData(_imageBytes!);
          downloadUrl = await ref.getDownloadURL();
          await user.updatePhotoURL(downloadUrl);
        }

        // Segarkan data sesi user
        await user.reload();

        // 3. SINKRONISASI LIVE: Simpan ke Firestore koleksi 'users' agar halaman detail bisa sinkron
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'photoUrl': downloadUrl,
          'email': user.email,
          'faculty': _facultyController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil berhasil diperbarui!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman Profile
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture Section - Bisa diklik untuk ganti foto
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF2F1EE),
                          width: 5,
                        ),
                      ),
                      child: ClipOval(
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : (currentUser?.photoURL != null
                                  ? Image.network(
                                      currentUser!.photoURL!,
                                      fit: BoxFit.cover,
                                    )
                                  : const CircleAvatar(
                                      backgroundColor: Color(0xFFF0F0F0),
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    color: Color(0xFF1A2235),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Full Name TextField
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FULL NAME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1A2235)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Faculty / Jurusan TextField
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FAKULTAS / JURUSAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _facultyController,
                    decoration: const InputDecoration(
                      hintText: "Contoh: Fakultas Teknik / S1 Informatika",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1A2235)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Email TextField (READ ONLY Tetap Terkunci)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMAIL ADDRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true, // Terkunci aman
                    style: const TextStyle(color: Colors.grey),
                    decoration: const InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Buttons Section
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2235),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'Discard Changes',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
