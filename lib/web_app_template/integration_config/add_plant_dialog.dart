import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/app_config.dart';

/// Adds a Factory/Plant to an EXISTING client's `plants` list — unlike
/// AddClientDialog, this never creates a new client doc. Returns the
/// selected plant name, or null if cancelled.
class AddPlantDialog extends StatefulWidget {
  final String clientName;
  final List<String> existingPlants;

  const AddPlantDialog({
    super.key,
    required this.clientName,
    required this.existingPlants,
  });

  @override
  State<AddPlantDialog> createState() => _AddPlantDialogState();
}

class _AddPlantDialogState extends State<AddPlantDialog> {
  List<Map<String, String>> _factories = [];
  bool _loading = true;
  String? _error;
  Map<String, String>? _selected;

  @override
  void initState() {
    super.initState();
    _loadFactories();
  }

  Future<void> _loadFactories() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBase}/factory'),
        headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        setState(() {
          _factories = data
              .map((f) => {
                    'id': (f['id'] ?? '').toString(),
                    'name': (f['name'] ?? f['id'] ?? '').toString(),
                  })
              .where((f) =>
                  f['id']!.isNotEmpty && !widget.existingPlants.contains(f['name']))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load factories (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot connect to server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF1A1F2E);
    final borderCol = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);
    final subColor = isLight ? const Color(0xFF64748B) : t.secondaryText;
    final accent = t.primary;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Icon(Icons.factory_outlined, size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Plant to ${widget.clientName}',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: t.primaryText)),
                      Text('Select a factory to attach to this existing client.',
                          style: GoogleFonts.poppins(fontSize: 11, color: subColor)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF2C354A),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: borderCol),
                    ),
                    child: Icon(Icons.close, size: 15, color: subColor),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(_error!, style: GoogleFonts.poppins(fontSize: 13, color: t.error)),
                          ),
                        )
                      : _factories.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text('No remaining factories to add.',
                                    style: GoogleFonts.poppins(fontSize: 13, color: subColor)),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Factory *',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: t.primaryText)),
                                const SizedBox(height: 5),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _selected == null ? borderCol : accent),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<Map<String, String>>(
                                      value: _selected,
                                      isExpanded: true,
                                      dropdownColor: cardBg,
                                      hint: Text('Select factory…', style: GoogleFonts.poppins(fontSize: 13, color: t.secondaryText)),
                                      style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText),
                                      items: _factories
                                          .map((f) => DropdownMenuItem(
                                                value: f,
                                                child: Text(f['name']!, style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText)),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selected = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: borderCol))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol)),
                    child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: t.secondaryText))),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(
                  opacity: _selected != null ? 1.0 : 0.4,
                  child: InkWell(
                    onTap: _selected != null ? () => Navigator.of(context).pop(_selected!['name']) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: t.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(
                        child: Text('Add Plant →',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isLight ? Colors.white : const Color(0xFF0A0E1A))),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
