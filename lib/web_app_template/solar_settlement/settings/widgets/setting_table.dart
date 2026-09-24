import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';

class SettingColumn {
  const SettingColumn(this.label,
      {this.flex = 10, this.align = Alignment.centerLeft});

  final String label;
  final int flex;
  final Alignment align;
}

/// A settings table: one widget or setting per row.
///
/// The width is pinned rather than left to the scroll view, for the same
/// reason as the ledger: inside a horizontal scroller a row is otherwise free
/// to size to its own content and the columns stop lining up. Below
/// [minWidth] the table scrolls instead of crushing its controls.
class SettingTable extends StatelessWidget {
  const SettingTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 860,
  });

  final List<SettingColumn> columns;
  final List<List<Widget>> rows;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth > minWidth ? c.maxWidth : minWidth;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(children: [
            Container(
              color: p.isLight
                  ? Colors.black.withOpacity(0.025)
                  : Colors.black.withOpacity(0.18),
              child: Row(children: [
                for (final col in columns)
                  _cell(
                    col,
                    Text(col.label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: p.mutedText)),
                    vertical: 11,
                  ),
              ]),
            ),
            for (var r = 0; r < rows.length; r++)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: p.border.withOpacity(0.6)),
                  ),
                ),
                child: Row(children: [
                  for (var i = 0; i < columns.length; i++)
                    _cell(columns[i],
                        i < rows[r].length ? rows[r][i] : const SizedBox()),
                ]),
              ),
          ]),
        ),
      );
    });
  }

  Widget _cell(SettingColumn col, Widget child, {double vertical = 12}) =>
      Expanded(
        flex: col.flex,
        child: Container(
          alignment: col.align,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: vertical),
          child: child,
        ),
      );
}
