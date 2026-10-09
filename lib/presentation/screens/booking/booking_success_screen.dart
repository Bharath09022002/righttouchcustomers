import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/theme/app_colors.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Booking confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Your pro will be assigned shortly. Track status under My bookings.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 28),
            AppButton(label: 'Track my bookings', fullWidth: true, onPressed: () => context.go('/bookings')),
            const SizedBox(height: 8),
            AppButton(label: 'Back to home', outlined: true, fullWidth: true, onPressed: () => context.go('/')),
          ]),
        ),
      ),
    );
  }
}
