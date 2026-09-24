import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav_pages.dart';
import '/flutter_flow/rbac.dart';
import '/flutter_flow/session_storage.dart';

/// Shows the "Set Home Page" dialog, letting the user pick which page opens
/// when they first log in. Shared between the desktop side nav and the
/// mobile nav drawer.
Future<void> showHomePageDialog(BuildContext context, String roles) async {
  final appState = AppStateNotifier.instance;
  final uid = appState.uid;
  if (uid == null || uid.isEmpty) return;

  final isSA = AppRoles.normalizeRole(roles) == AppRoles.superAdmin;
  final accessiblePages = kNavigablePages.where((p) {
    if (isSA) return true;
    if (p.module == null) return true;
    return appState.accessibleModules.contains(p.module);
  }).toList();

  if (accessiblePages.isEmpty) return;

  final isLight = Theme.of(context).brightness == Brightness.light;
  final theme = FlutterFlowTheme.of(context);
  final accent = isLight ? const Color(0xFF0057FF) : const Color(0xFF00F5FF);
  final current = appState.landingPage ?? '';

  final selected = await showDialog<String>(
    context: context,
    builder: (ctx) {
      String? picked = current.isNotEmpty ? current : null;
      String query = '';
      final searchCtrl = TextEditingController();
      return StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = accessiblePages
              .where((p) => p.label.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return AlertDialog(
            backgroundColor: isLight ? theme.secondaryBackground : const Color(0xFF0A1628),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: accent.withOpacity(0.3)),
            ),
            title: Text(
              'Set Home Page',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isLight ? theme.txtPrimary : Colors.white,
              ),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the page to open when you first log in.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isLight ? theme.txtSecondary : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isLight ? theme.txtPrimary : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search pages...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isLight ? theme.txtTertiary : Colors.white38,
                      ),
                      prefixIcon: Icon(Icons.search, size: 18,
                          color: isLight ? theme.txtTertiary : Colors.white38),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16,
                                  color: isLight ? theme.txtTertiary : Colors.white38),
                              onPressed: () {
                                searchCtrl.clear();
                                setS(() => query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: isLight
                          ? theme.primaryBackground
                          : Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: accent.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: accent.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: accent.withOpacity(0.6)),
                      ),
                    ),
                    onChanged: (v) => setS(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${filtered.length} page${filtered.length == 1 ? '' : 's'} available',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isLight ? theme.txtTertiary : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No pages found.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isLight ? theme.txtTertiary : Colors.white38,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: filtered.map((page) {
                                final isSelected = picked == page.routeName;
                                return InkWell(
                                  onTap: () => setS(() => picked = page.routeName),
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelected ? accent.withOpacity(0.12) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? accent.withOpacity(0.5) : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          size: 16,
                                          color: isSelected ? accent : (isLight ? theme.txtTertiary : Colors.white38),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            page.label,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                              color: isSelected ? accent : (isLight ? theme.txtPrimary : Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text('Cancel', style: GoogleFonts.poppins(color: isLight ? theme.txtSecondary : Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isLight ? Colors.white : const Color(0xFF0A1628),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: picked == null ? null : () => Navigator.of(ctx).pop(picked),
                child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );

  if (selected == null || !context.mounted) return;

  try {
    await FirebaseFirestore.instance
        .collection('roles')
        .doc(uid)
        .set({'landing_page': selected}, SetOptions(merge: true));
    appState.landingPage = selected;
    SessionStorage.saveSetting('landing_page', selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Home page updated.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: accent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save home page.', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
