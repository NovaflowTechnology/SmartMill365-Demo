import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CustomDialogSection {
  final int? number;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const CustomDialogSection({
    this.number,
    required this.title,
    required this.subtitle,
    required this.children,
  });
}

class CustomDialog extends StatefulWidget {
  final GlobalKey<FormState>? formKey;
  final IconData              icon;
  final String                title;
  final String                subtitle;
  final List<CustomDialogSection> sections;
  final Future<bool> Function()   onSubmit;
  final bool   requiredNote;
  final String submitLabel;
  final String cancelLabel;
  final double maxWidth;

  const CustomDialog({
    super.key,
    this.formKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.onSubmit,
    this.requiredNote = false,
    this.submitLabel  = 'SUBMIT',
    this.cancelLabel  = 'CANCEL',
    this.maxWidth     = 760,
  });

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  final _scroll = ScrollController();
  bool _loading = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (widget.formKey != null) {
      if (!widget.formKey!.currentState!.validate()) return;
    }
    setState(() => _loading = true);
    final shouldClose = await widget.onSubmit();
    if (!mounted) return;
    setState(() => _loading = false);
    if (shouldClose) Navigator.of(context).pop();
  }

  Widget _badge(int number, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _sectionCard(CustomDialogSection s, bool isLight, Color cardBg, Color cardBorder, Color titleColor, Color subtitleColor, Color badgeColor) {
    final screenW = MediaQuery.of(context).size.width;
    final cardPad = screenW < 600 ? 14.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.08 : 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.number != null) ...[
                _badge(s.number!, badgeColor),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(s.subtitle, style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...s.children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bgStart      = isLight ? const Color(0xFFF8FAFC) : t.softBlue2;
    final bgEnd        = isLight ? const Color(0xFFEEF2FF) : t.primaryBackground;
    final barColor     = isLight ? const Color(0xFFFFFFFF) : t.softBlue2;
    final cardBg       = isLight ? const Color(0xFFFFFFFF) : t.softBlue1;
    final cardBorder   = isLight ? const Color(0xFFE2E8F0) : t.vizGlowCore;
    final titleColor   = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final subtitleColor= isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final mutedColor   = isLight ? const Color(0xFF64748B) : const Color(0xFF8B949E);
    final dimColor     = isLight ? const Color(0xFF94A3B8) : const Color(0xFF5C6987);
    final closeBg      = isLight ? const Color(0xFFF1F5F9) : t.alternate;
    final cancelBg     = isLight ? const Color(0xFFF1F5F9) : t.softBlue2;
    final cancelBorder = isLight ? const Color(0xFFCBD5E1) : t.vizGlowCore;
    final submitTextColor = isLight ? Colors.white : const Color(0xFF0A0E1A);
    final badgeColor   = t.primary;

    Widget cardGroup = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.sections.length; i++) ...[
          _sectionCard(widget.sections[i], isLight, cardBg, cardBorder, titleColor, subtitleColor, badgeColor),
          if (i < widget.sections.length - 1) const SizedBox(height: 16),
        ],
      ],
    );

    Widget body = cardGroup;
    if (widget.formKey != null) body = Form(key: widget.formKey, child: body);

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd, bgEnd],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: barColor,
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.primary.withOpacity(0.2), width: 1),
                    ),
                    child: Center(child: Icon(widget.icon, size: 18, color: t.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: TextStyle(color: dimColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: closeBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: cardBorder, width: 1)),
                      child: Icon(Icons.close, size: 16, color: mutedColor),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ────────────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hPad = constraints.maxWidth < 600 ? 14.0 : 28.0;
                  return SingleChildScrollView(
                    controller: _scroll,
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: widget.maxWidth),
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                        child: body,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── FOOTER ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: barColor,
              child: Row(
                children: [
                  if (widget.requiredNote) ...[
                    Icon(Icons.info_outline, size: 14, color: dimColor),
                    const SizedBox(width: 7),
                    Text('Fields marked with * are required', style: TextStyle(color: dimColor, fontSize: 12)),
                  ],
                  const Spacer(),
                  InkWell(
                    onTap: _loading ? null : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(color: cancelBg, borderRadius: BorderRadius.circular(9), border: Border.all(color: cancelBorder, width: 1)),
                      child: Text(widget.cancelLabel, style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _loading ? null : _handleSubmit,
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                      decoration: BoxDecoration(
                        color: _loading ? t.primary.withOpacity(0.5) : t.primary,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _loading ? [] : [BoxShadow(color: t.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: _loading
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: submitTextColor))
                          : Text(widget.submitLabel, style: TextStyle(color: submitTextColor, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
