import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kHeaderBg   = Color(0xFF000B2E);
const kBodyBg     = Color(0xFFF2F4F8);
const kCardBg     = Color(0xFFEAF1FB);
const kCardBorder = Color(0xFFD0E3F5);
const kAccentBlue = Color(0xFF2F73C6);
const kGreen      = Color(0xFF2DC76D);
const kTextDark   = Color(0xFF0D1B3E);
const kSubText    = Color(0xFF6B7A99);

class DeployButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DeployButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Save & Deploy to Billing Engine',
              style: GoogleFonts.poppins(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
