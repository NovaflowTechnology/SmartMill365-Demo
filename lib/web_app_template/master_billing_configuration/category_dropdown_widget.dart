// billing_config_components.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'billing_config_model.dart';

// ─────────────────────────────────────────────
//  Shared colour tokens
// ─────────────────────────────────────────────
const kHeaderBg   = Color(0xFF000B2E);
const kBodyBg     = Color(0xFFF2F4F8);
const kCardBg     = Color(0xFFEAF1FB);
const kCardBorder = Color(0xFFD0E3F5);
const kAccentBlue = Color(0xFF2F73C6);
const kGreen      = Color(0xFF2DC76D);
const kTextDark   = Color(0xFF0D1B3E);
const kSubText    = Color(0xFF6B7A99);

// ─────────────────────────────────────────────
//  Category Dropdown (header)
// ─────────────────────────────────────────────
class CategoryDropdown extends StatelessWidget {
  final VoltageCategory selected;
  final ValueChanged<VoltageCategory> onChanged;

  const CategoryDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoltageCategory>(
      onSelected: onChanged,
      color: const Color(0xFF1A2744),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => VoltageCategory.values.map((cat) {
        return PopupMenuItem(
          value: cat,
          child: Row(
            children: [
              Icon(
                selected == cat ? Icons.check : null,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Category: ${cat.label}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Category: ${selected.label}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: kTextDark),
          ],
        ),
      ),
    );
  }
}