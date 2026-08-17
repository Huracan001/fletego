import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/fletego_brand_mark.dart';

/// Holds until auth status is known; router then redirects.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);

    return const Scaffold(
      backgroundColor: FletegoColors.navy,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FletegoBrandMark(light: true),
              SizedBox(height: 32),
              Text(
                'Move cargo. Move business.',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: FletegoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
