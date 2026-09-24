import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/widget_config_dialog.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SelectDialogWidget extends StatefulWidget {
  final int cellIndex;
  final String uid;
  final String templateId;

  /// Called with the saved cell config so the parent can update its list immediately.
  final void Function(KanbanCellConfig saved)? onSaved;

  const SelectDialogWidget({
    Key? key,
    required this.cellIndex,
    required this.uid,
    required this.templateId,
    this.onSaved,
  }) : super(key: key);

  @override
  State<SelectDialogWidget> createState() => _SelectDialogWidgetState();
}

class _SelectDialogWidgetState extends State<SelectDialogWidget> {
  final _searchController = TextEditingController();
  WidgetMeta? _selected;
  String _query = '';

  List<WidgetMeta> get _filtered => _query.isEmpty
      ? kWidgetRegistry
      : kWidgetRegistry
          .where((w) =>
              w.name.toLowerCase().contains(_query.toLowerCase()) ||
              w.description.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openConfig() async {
    if (_selected == null) return;
    if (!mounted) return;

    // Show Step 2 first (context is still valid here), then close Step 1 on success
    final saved = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => WidgetConfigDialog(
        cellIndex: widget.cellIndex,
        widgetMeta: _selected!,
        uid: widget.uid,
        templateId: widget.templateId,
        onSaved: widget.onSaved,
      ),
    );

    if (mounted && saved == true) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Dialog(
      backgroundColor: theme.primaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: SizedBox(
        width: responsiveDialogWidth(context, 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Select Widget',
                          style: GoogleFonts.poppins(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w500)),
                      Text('Cell ${widget.cellIndex + 1} — pick a widget then configure it',
                          style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 12)),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.secondaryText, size: 20),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: theme.primaryText, fontSize: 13, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Search for a widget here…',
                  hintStyle: TextStyle(color: theme.secondaryText, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: theme.secondaryText, size: 18),
                  filled: true, fillColor: const Color(0xFF001055),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.primary.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.primary.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.primary)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Widget grid
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('No widgets found',
                            style: TextStyle(color: theme.secondaryText, fontFamily: 'Poppins')),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final w = _filtered[index];
                        final isSelected = _selected?.type == w.type;
                        return _WidgetCard(
                          meta: w,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selected = isSelected ? null : w),
                        );
                      },
                    ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_selected != null)
                    Row(children: [
                      Icon(Icons.check_circle_outline, size: 14, color: theme.primary),
                      const SizedBox(width: 6),
                      Text(_selected!.name,
                          style: TextStyle(color: theme.primary, fontSize: 12, fontFamily: 'Poppins')),
                    ])
                  else
                    Text('Select a widget to continue',
                        style: TextStyle(color: theme.secondaryText, fontSize: 12, fontFamily: 'Poppins')),
                  Row(children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryText,
                        side: BorderSide(color: theme.primary.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _selected == null ? null : _openConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.primary.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Next: Configure', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  final WidgetMeta meta;
  final bool isSelected;
  final VoidCallback onTap;
  const _WidgetCard({required this.meta, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final decoration = isSelected
        ? BoxDecoration(color: theme.primary.withOpacity(0.12), border: Border.all(color: theme.primary, width: 1.5))
        : const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white12), right: BorderSide(color: Colors.white12)));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: decoration,
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meta.name.toUpperCase(),
                  style: TextStyle(color: theme.primary, fontSize: 11, fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins', letterSpacing: 0.3)),
              const SizedBox(height: 4),
              Expanded(
                child: Text(meta.description,
                    style: TextStyle(color: theme.secondaryText, fontSize: 11, fontFamily: 'Poppins', height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (isSelected)
              Positioned(top: 0, right: 0, child: Icon(Icons.check_circle, size: 16, color: theme.primary)),
          ],
        ),
      ),
    );
  }
}