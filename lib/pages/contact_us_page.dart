import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reusea/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color bgIconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow(),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.03), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgIconColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      color: AppTheme.secondaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.lexend(
                      color: AppTheme.darkNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.lightBlueGrey, size: 18),
          ],
        ),
      ),
    );
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
                        'Hubungi Kami',
                        style: GoogleFonts.lexend(
                          color: AppTheme.darkNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Header Illustration/Banner
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            size: 72,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Ada yang bisa kami bantu?",
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hubungi tim pengembang ReUsea UNESA jika Anda memiliki pertanyaan atau kendala dalam aplikasi.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: AppTheme.secondaryBlue,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact Cards
                  _buildContactCard(
                    icon: Icons.chat_outlined,
                    title: "WHATSAPP",
                    value: "+62 818-0331-7261",
                    iconColor: Colors.green,
                    bgIconColor: Colors.green.withValues(alpha: 0.1),
                    onTap: () async {
                      final Uri url = Uri.parse("https://wa.me/6281803317261");
                      try {
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          await launchUrl(url, mode: LaunchMode.platformDefault);
                        }
                      } catch (_) {
                        await launchUrl(url, mode: LaunchMode.platformDefault);
                      }
                    },
                  ),
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: "EMAIL RESMI",
                    value: "reuseasupport@gmail.com",
                    iconColor: Colors.blue,
                    bgIconColor: Colors.blue.withValues(alpha: 0.1),
                    onTap: () async {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'reuseasupport@gmail.com',
                        queryParameters: {
                          'subject': 'Bantuan ReUsea',
                        },
                      );
                      try {
                        if (!await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication)) {
                          await launchUrl(emailLaunchUri, mode: LaunchMode.platformDefault);
                        }
                      } catch (_) {
                        await launchUrl(emailLaunchUri, mode: LaunchMode.platformDefault);
                      }
                    },
                  ),
                  _buildContactCard(
                    icon: Icons.camera_alt_outlined,
                    title: "INSTAGRAM",
                    value: "@reusea_unesa",
                    iconColor: AppTheme.sunsetOrange,
                    bgIconColor: AppTheme.sunsetOrange.withValues(alpha: 0.1),
                    onTap: () async {
                      final Uri url = Uri.parse("https://www.instagram.com/reusea_unesa/");
                      try {
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          await launchUrl(url, mode: LaunchMode.platformDefault);
                        }
                      } catch (_) {
                        await launchUrl(url, mode: LaunchMode.platformDefault);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      "Kami biasanya merespons pesan Anda dalam waktu 24 jam kerja. Terima kasih atas kesabaran Anda!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        color: AppTheme.darkNavy,
                        fontSize: 11,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
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
}
