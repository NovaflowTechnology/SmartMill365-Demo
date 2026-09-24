import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Small colored dot + label used in the chart panel's legend row.
class TblLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const TblLegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(fontSize: 10.5, color: color.withOpacity(0.9))),
      ],
    );
  }
}
