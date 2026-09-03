import 'package:flutter/material.dart';
import 'package:petani_maju/core/constants/colors.dart';
import 'package:petani_maju/core/services/cache_service.dart';
import 'package:petani_maju/features/premium/screens/purchase_premium_screen.dart';

/// Dialog batas kuota chat gratis untuk akun gratis.
///
/// Dipakai dari beberapa tempat: pengecekan awal di [ChatInputBar] dan
/// penolakan dari [ChatbotBloc] ketika pesan dikirim lewat jalur lain
/// (tombol saran, hasil scan, riwayat), jadi bentuknya disatukan di sini.
Future<void> showUpgradeToProDialog(BuildContext context) {
  final resetDate =
      CacheService().getSubscriptionDetails()['freeChatResetDate'] as DateTime?;

  // Kuota terisi ulang pada tengah malam berikutnya. Untuk user, "besok"
  // lebih jelas daripada tanggal, kecuali sisa waktunya tinggal beberapa jam.
  final hoursLeft = resetDate?.difference(DateTime.now()).inHours;
  final resetLabel = hoursLeft == null
      ? 'besok'
      : (hoursLeft < 1 ? 'sebentar lagi' : 'besok pukul 00.00');

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFA000),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Batas Chat Gratis Tercapai',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Akun gratis dibatasi 3 jawaban Asisten Tani per hari.'
              'Kuotamu terisi ulang '
              '$resetLabel. Upgrade ke Petani Maju PRO untuk konsultasi AI '
              'sepuasnya tanpa batas kuota!',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () {
                  final navigator = Navigator.of(ctx);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => const PurchasePremiumScreen(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded,
                        size: 18, color: Color(0xFFFFD700)),
                    SizedBox(width: 6),
                    Text(
                      'Upgrade ke PRO Sekarang',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Nanti Saja',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
