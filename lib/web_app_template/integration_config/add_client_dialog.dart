import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'integration_config_models.dart';

/// Creates a brand-new top-level client. The Client Code is freely chosen by
/// the admin and becomes the client's ID / x-client-id — it no longer needs
/// to equal a General Factory Setting Factory ID. Routing users to the
/// correct client instead happens via "+ Add Plant" (attaches a factory to
/// this client's `plants` list) combined with the factory-name match in
/// AppConfig.initForUser.
class AddClientDialog extends StatefulWidget {
  final List<String> existingClientIds;

  const AddClientDialog({super.key, required this.existingClientIds});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _nameCtr = TextEditingController();
  final _codeCtr = TextEditingController();
  final _plantsCtr = TextEditingController();
  String _plan = 'Trial';
  String? _codeError;

  @override
  void dispose() {
    _nameCtr.dispose();
    _codeCtr.dispose();
    _plantsCtr.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameCtr.text.trim();
    final code = _codeCtr.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) return;
    if (widget.existingClientIds.contains(code)) {
      setState(() => _codeError = 'Code "$code" is already in use by an existing client');
      return;
    }

    final plants = _plantsCtr.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final ts = '${now.year}-${_p(now.month)}-${_p(now.day)} ${_p(now.hour)}:${_p(now.minute)}';

    final config = ClientConfig(
      id: code,
      name: name,
      code: code,
      plan: _plan,
      domain: '${code.toLowerCase()}.sf365.com',
      plants: plants,
      checklist: const SetupChecklist(created: true),
      history: [HistoryEntry(ts: ts, who: 'Admin', msg: 'Client record created')],
    );
    Navigator.of(context).pop(config);
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF1A1F2E);
    final borderCol = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);
    final subColor = isLight ? const Color(0xFF64748B) : t.secondaryText;
    final accent = t.primary;
    final fieldBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final name = _nameCtr.text.trim();
    final code = _codeCtr.text.trim();
    final canSubmit = name.isNotEmpty && code.isNotEmpty;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: accent.withOpacity(0.25)),
                    ),
                    child: Icon(Icons.add_business_rounded, size: 18, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Client',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: t.primaryText)),
                        Text('Create a new client domain. Configure database connections after creation.',
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
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client Name *',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: t.primaryText)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _nameCtr,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText),
                    decoration: InputDecoration(
                      hintText: 'e.g. Petronas Chemicals',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: t.secondaryText),
                      filled: true,
                      fillColor: fieldBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCol), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accent), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Client Code *',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: t.primaryText)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _codeCtr,
                    onChanged: (_) => setState(() => _codeError = null),
                    style: GoogleFonts.sourceCodePro(fontSize: 13, color: t.primaryText),
                    decoration: InputDecoration(
                      hintText: 'e.g. PET',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: t.secondaryText),
                      filled: true,
                      fillColor: fieldBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _codeError != null ? t.error : borderCol), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _codeError != null ? t.error : accent), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (_codeError != null) ...[
                    const SizedBox(height: 4),
                    Text(_codeError!, style: GoogleFonts.poppins(fontSize: 11, color: t.error)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('Domain: ', style: GoogleFonts.poppins(fontSize: 11, color: subColor)),
                    Text(
                      code.isEmpty ? '—' : '${code.toLowerCase()}.sf365.com',
                      style: GoogleFonts.sourceCodePro(fontSize: 11, color: code.isEmpty ? subColor : accent, fontWeight: FontWeight.w600),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  Text('Plants (comma separated)',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: t.primaryText)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _plantsCtr,
                    style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Plant 1, Plant 2',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: t.secondaryText),
                      filled: true,
                      fillColor: fieldBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCol), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accent), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Subscription Plan',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: t.primaryText)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _plan,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText),
                        items: ['Trial', 'Basic', 'Enterprise']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText))))
                            .toList(),
                        onChanged: (v) => setState(() => _plan = v ?? 'Trial'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: borderCol))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ghostBtn('Cancel', () => Navigator.of(context).pop(), t, isLight, borderCol),
                  const SizedBox(width: 10),
                  Opacity(
                    opacity: canSubmit ? 1.0 : 0.4,
                    child: _primaryBtn('Create Client →', canSubmit ? _confirm : () {}, t, isLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghostBtn(String label, VoidCallback onTap, FlutterFlowTheme t, bool isLight, Color borderCol) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol)),
        child: Center(child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: t.secondaryText))),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap, FlutterFlowTheme t, bool isLight) {
    return InkWell(
      onTap: onTap,
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
          child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isLight ? Colors.white : const Color(0xFF0A0E1A))),
        ),
      ),
    );
  }
}
