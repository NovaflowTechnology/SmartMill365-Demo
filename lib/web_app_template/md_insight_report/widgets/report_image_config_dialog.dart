import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/services/app_config.dart';

import '../md_insight_report_image_config.dart';
import '../models/equipment_candidate.dart';
import '../models/equipment_row.dart';

const _allowedExtensions = ['jpg', 'jpeg', 'png'];
const _maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB

/// Report Settings editor: the report's two configurable images
/// (plant-status background photo, footer brand logo — same
/// pick-validate-upload-to-Firebase-Storage pattern as the Kanban Dashboard
/// Settings branding photo upload, rather than a raw URL field; leaving both
/// unset/removed falls back to the report's bundled asset images) plus,
/// scoped to [plantCode], a checklist of which of that plant's candidate
/// equipment should count toward the Equipment Analysis ranking.
class ReportImageConfigDialog extends StatefulWidget {
  final MdInsightReportImageConfig initialConfig;
  final String plantCode;
  final List<MdEquipmentCandidate> equipmentCandidates;

  /// The plant's Equipment Analysis ranking as currently shown on the
  /// report page (top 10, highest demand first). Used purely to sort the
  /// checklist so what's actually ranked right now surfaces first, each
  /// tagged with its current kW — so unchecking one has an obviously
  /// visible effect, instead of the checklist reading as an unordered
  /// dump of every resolved candidate.
  final List<EquipmentRow> currentRanking;

  const ReportImageConfigDialog({
    super.key,
    required this.initialConfig,
    required this.plantCode,
    required this.equipmentCandidates,
    this.currentRanking = const [],
  });

  /// Shows the dialog and returns the new config on Save, or null if the
  /// user cancelled. [plantCode] and [equipmentCandidates] scope the
  /// equipment checklist to the currently selected plant; [currentRanking]
  /// lets it show each candidate's live rank/value where applicable.
  static Future<MdInsightReportImageConfig?> show(
    BuildContext context,
    MdInsightReportImageConfig initialConfig, {
    required String plantCode,
    required List<MdEquipmentCandidate> equipmentCandidates,
    List<EquipmentRow> currentRanking = const [],
  }) {
    return showDialog<MdInsightReportImageConfig>(
      context: context,
      builder: (_) => ReportImageConfigDialog(
        initialConfig: initialConfig,
        plantCode: plantCode,
        equipmentCandidates: equipmentCandidates,
        currentRanking: currentRanking,
      ),
    );
  }

  @override
  State<ReportImageConfigDialog> createState() =>
      _ReportImageConfigDialogState();
}

class _ReportImageConfigDialogState extends State<ReportImageConfigDialog> {
  final _picker = ImagePicker();

  String? _plantUrl;
  Uint8List? _plantBytes;
  String? _plantExtension;

  String? _logoUrl;
  Uint8List? _logoBytes;
  String? _logoExtension;

  /// Tags currently excluded from this plant's Equipment Analysis ranking.
  /// A candidate is "included" (checked) iff its tag isn't in this set.
  late Set<String> _excludedTags;

  /// [widget.equipmentCandidates], reordered so whatever's currently in
  /// [widget.currentRanking] appears first (in ranking order), followed by
  /// the rest alphabetically — computed once since neither list changes
  /// while this dialog is open.
  late List<MdEquipmentCandidate> _orderedCandidates;

  /// label -> its current ranking row, for the kW chip next to ranked items.
  late Map<String, EquipmentRow> _rankByLabel;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _plantUrl = widget.initialConfig.plantBackgroundImageUrl;
    _logoUrl = widget.initialConfig.footerLogoImageUrl;
    _excludedTags = {
      ...?widget.initialConfig.excludedEquipmentByPlant[widget.plantCode],
    };

    _rankByLabel = {for (final r in widget.currentRanking) r.name: r};
    final ranked = <MdEquipmentCandidate>[];
    final unranked = <MdEquipmentCandidate>[];
    for (final c in widget.equipmentCandidates) {
      (_rankByLabel.containsKey(c.label) ? ranked : unranked).add(c);
    }
    // widget.currentRanking already arrives sorted highest-demand-first
    // (the backend's top-10 ranking order) — sort `ranked` to match it
    // rather than the candidate list's own (arbitrary) order.
    ranked.sort((a, b) =>
        _rankByLabel[a.label]!.demandKw.compareTo(_rankByLabel[b.label]!.demandKw) *
        -1);
    unranked.sort((a, b) => a.label.compareTo(b.label));
    _orderedCandidates = [...ranked, ...unranked];
  }

  Future<void> _pick({required bool isPlant}) async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    final ext = picked.name.toLowerCase().split('.').last;
    if (!_allowedExtensions.contains(ext)) {
      setState(() => _error = 'Only JPG and PNG images are allowed.');
      return;
    }
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > _maxImageSizeBytes) {
      setState(() => _error = 'Image must be smaller than 5 MB.');
      return;
    }
    setState(() {
      _error = null;
      if (isPlant) {
        _plantBytes = bytes;
        _plantExtension = ext;
      } else {
        _logoBytes = bytes;
        _logoExtension = ext;
      }
    });
  }

  void _remove({required bool isPlant}) {
    setState(() {
      if (isPlant) {
        _plantUrl = null;
        _plantBytes = null;
        _plantExtension = null;
      } else {
        _logoUrl = null;
        _logoBytes = null;
        _logoExtension = null;
      }
    });
  }

  void _toggleEquipment(String tag, bool included) {
    setState(() {
      if (included) {
        _excludedTags.remove(tag);
      } else {
        _excludedTags.add(tag);
      }
    });
  }

  Future<String> _upload(Uint8List bytes, String ext, String fileName) async {
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('md_insight_report_images/$fileName.$ext');
    final snapshot = await ref
        .putData(bytes, SettableMetadata(contentType: contentType))
        .timeout(const Duration(seconds: 60),
            onTimeout: () => throw Exception('Upload timed out'));
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      var plantUrl = _plantUrl;
      if (_plantBytes != null) {
        plantUrl = await _upload(_plantBytes!, _plantExtension ?? 'jpg',
            'plant_bg_${AppConfig.clientId}');
      }
      var logoUrl = _logoUrl;
      if (_logoBytes != null) {
        logoUrl = await _upload(_logoBytes!, _logoExtension ?? 'png',
            'footer_logo_${AppConfig.clientId}');
      }
      if (!mounted) return;
      Navigator.of(context).pop(MdInsightReportImageConfig(
        plantBackgroundImageUrl: plantUrl,
        footerLogoImageUrl: logoUrl,
        excludedEquipmentByPlant: {
          ...widget.initialConfig.excludedEquipmentByPlant,
          widget.plantCode: _excludedTags.toList(),
        },
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Upload failed: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AlertDialog(
      backgroundColor: theme.secondaryBackground,
      title: Text(
        'Report Settings',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: theme.primaryText),
      ),
      content: SizedBox(
        width: responsiveDialogWidth(context, 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(theme, 'Report Images'),
              const SizedBox(height: 10),
              _imageSlot(
                theme: theme,
                label: 'Plant status background photo',
                currentUrl: _plantUrl,
                stagedBytes: _plantBytes,
                onPick: () => _pick(isPlant: true),
                onRemove: () => _remove(isPlant: true),
              ),
              const SizedBox(height: 20),
              _imageSlot(
                theme: theme,
                label: 'Footer logo',
                currentUrl: _logoUrl,
                stagedBytes: _logoBytes,
                onPick: () => _pick(isPlant: false),
                onRemove: () => _remove(isPlant: false),
              ),
              const SizedBox(height: 24),
              _sectionLabel(theme, 'Equipment Analysis Ranking'),
              const SizedBox(height: 6),
              Text(
                'Uncheck any equipment that shouldn\'t count toward this '
                'plant\'s Equipment Analysis ranking.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: theme.secondaryText),
              ),
              const SizedBox(height: 10),
              _equipmentChecklist(theme),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _sectionLabel(FlutterFlowTheme theme, String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.primaryText),
      );

  /// Same bounded scrollable checkbox-list pattern as
  /// carbon_dashboard_config_setting_widget.dart's device/equipment
  /// multi-selects. Currently-ranked equipment sorts first (matching its
  /// rank order) with a kW chip; everything else follows alphabetically —
  /// see [_orderedCandidates]/[_rankByLabel] in initState.
  Widget _equipmentChecklist(FlutterFlowTheme theme) {
    if (_orderedCandidates.isEmpty) {
      return Text(
        'No equipment found for this plant.',
        style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: _orderedCandidates.map((c) {
            final included = !_excludedTags.contains(c.tag);
            final rank = _rankByLabel[c.label];
            return CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: included,
              onChanged: (v) => _toggleEquipment(c.tag, v ?? true),
              title: Text(c.label,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: theme.primaryText)),
              subtitle: rank == null
                  ? null
                  : Text('Currently ranked — ${rank.demandKw.toStringAsFixed(0)} kW',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: theme.secondaryText)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _imageSlot({
    required FlutterFlowTheme theme,
    required String label,
    required String? currentUrl,
    required Uint8List? stagedBytes,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final hasImage =
        stagedBytes != null || (currentUrl != null && currentUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12.5, color: theme.secondaryText)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 72,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.alternate),
                color: theme.primaryBackground,
              ),
              clipBehavior: Clip.antiAlias,
              child: stagedBytes != null
                  ? Image.memory(stagedBytes, fit: BoxFit.cover)
                  : (currentUrl != null && currentUrl.isNotEmpty)
                      ? Image.network(
                          currentUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.secondaryText,
                              size: 18),
                        )
                      : Icon(Icons.image_outlined,
                          color: theme.secondaryText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: Text(hasImage ? 'Change Photo' : 'Upload Photo'),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                  if (hasImage)
                    TextButton(
                        onPressed: onRemove, child: const Text('Remove')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
