import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/utils/theme.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = "UI/UX";
  int _appRating = 5;
  bool _isSubmitting = false;

  final List<String> _categories = ["UI/UX", "Bug / Masalah", "Transaksi", "Lainnya"];

  void _submitFeedback() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    // Simulate submission delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Success Feedback",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.bounceOut),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.ecoTeal.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.ecoTeal,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Terima Kasih!",
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Terima kasih atas masukan Anda. Saran Anda sangat membantu kami untuk mengembangkan ReUsea menjadi lebih baik.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppTheme.secondaryBlue,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Tutup dialog
                      Navigator.pop(context); // Kembali ke halaman sebelumnya
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      "Kembali",
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OceanGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button & Title Row
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
                          'Kritik & Saran',
                          style: GoogleFonts.lexend(
                            color: AppTheme.darkNavy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Top Card Intro
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.softShadow(),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Text("💡", style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Bantu kami menyempurnakan ReUsea! Berikan masukan, temuan bug, atau saran pengembangan fitur baru.",
                              style: GoogleFonts.lexend(
                                color: AppTheme.darkNavy,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.softShadow(),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.04), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nama
                          Text(
                            "NAMA LENGKAP",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                            validator: (val) => val == null || val.trim().isEmpty ? "Nama wajib diisi" : null,
                            decoration: InputDecoration(
                              hintText: "Masukkan nama Anda",
                              hintStyle: GoogleFonts.lexend(color: AppTheme.lightBlueGrey, fontWeight: FontWeight.normal),
                              filled: true,
                              fillColor: AppTheme.bgLight.withValues(alpha: 0.3),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.05)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Kategori Masukan
                          Text(
                            "KATEGORI MASUKAN",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: Colors.white,
                            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.bgLight.withValues(alpha: 0.3),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.05)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // 3. Kritik atau Saran
                          Text(
                            "KRITIK ATAU SARAN",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _contentController,
                            maxLines: 5,
                            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                            validator: (val) => val == null || val.trim().isEmpty ? "Kritik/saran wajib diisi" : null,
                            decoration: InputDecoration(
                              hintText: "Tuliskan pengalaman Anda menggunakan aplikasi, keluhan, atau ide fitur baru di sini...",
                              hintStyle: GoogleFonts.lexend(color: AppTheme.lightBlueGrey, fontWeight: FontWeight.normal),
                              filled: true,
                              fillColor: AppTheme.bgLight.withValues(alpha: 0.3),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.05)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4. Rating Pengalaman
                          Text(
                            "RATING PENGALAMAN APLIKASI",
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondaryBlue,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              int starVal = index + 1;
                              bool isSelected = starVal <= _appRating;
                              return IconButton(
                                icon: Icon(
                                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: AppTheme.sunYellow,
                                  size: 36,
                                ),
                                onPressed: () {
                                  setState(() => _appRating = starVal);
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Kirim Masukan',
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
