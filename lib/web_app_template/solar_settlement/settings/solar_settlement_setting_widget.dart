import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';
import 'package:smartmachine365/utils/tou_window.dart';

import '../logic/settlement_calculator.dart';
import '../logic/settlement_loader.dart';
import '../logic/settlement_pricing.dart';
import '../logic/settlement_setup_resolver.dart';
import '../models/settlement_config.dart';
import '../models/settlement_masters.dart';
import '../models/settlement_models.dart';
import '../services/settlement_config_service.dart';
import '../services/solar_settlement_service.dart';
import '../solar_settlement_theme.dart';
import 'widgets/impact_bar.dart';
import 'widgets/kpi_strip_panel.dart';
import 'widgets/ledger_rules_panel.dart';
import 'widgets/setting_badges.dart';
import 'widgets/setting_header.dart';
import 'widgets/setting_legend.dart';
import 'widgets/setting_panel.dart';
import 'widgets/settlement_rate_panel.dart';
import 'widgets/supply_agreement_panel.dart';
import 'widgets/tnb_reference_panel.dart';
import 'widgets/tou_reference_strip.dart';
import 'widgets/version_dialog.dart';

/// Solar Settlement Setting — the terms the dashboard settles by.
///
/// This file holds the draft and the page's flow: load, edit, preview, save.
/// Each panel is its own widget under `widgets/`, the arithmetic is in
/// `logic/`, and every request goes through `services/`, so the page reads as
/// a list of what can be configured and in what order.
///
/// Only a Super Admin may open it. The dashboard hides the entry point from
/// everyone else, and this page checks again on its own, because a route can
/// be typed into the address bar.
class SolarSettlementSettingWidget extends StatefulWidget {
  const SolarSettlementSettingWidget({super.key});

  @override
  State<SolarSettlementSettingWidget> createState() =>
      _SolarSettlementSettingWidgetState();
}

class _SolarSettlementSettingWidgetState
    extends State<SolarSettlementSettingWidget> {
  static bool get _isSuperAdmin =>
      AppRoles.normalizeRole(AppStateNotifier.instance.userRole ?? '') ==
      AppRoles.superAdmin;

  SettlementConfig _saved = const SettlementConfig();
  SettlementConfig _draft = const SettlementConfig();
  bool _published = false;
  bool _loadFailed = false;
  bool _loading = true;
  bool _saving = false;

  SettlementMasters _masters = const SettlementMasters();
  TouWindow? _tou;

  TnbRates _tnb = const TnbRates();
  bool _tnbLoading = false;
  String _tnbKey = '';
  int _tnbToken = 0;

  // The version whose prices are being edited.
  int _version = 1;
  DateTime _effectiveFrom = _thisMonth();
  RateTier _peak = const RateTier();
  RateTier _offPeak = const RateTier();

  SettlementPeriod? _preview;
  bool _previewLoading = false;
  String _previewKey = '';
  int _previewToken = 0;

  final Set<String> _collapsed = {};

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  void initState() {
    super.initState();
    if (_isSuperAdmin) {
      _init();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    // Stops any preview still fetching hourly records for a page that is gone.
    _previewToken++;
    _tnbToken++;
    super.dispose();
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final uid = AppStateNotifier.instance.uid ?? '';
    final results = await Future.wait<Object?>([
      SettlementConfigService.load(),
      SettlementConfigService.loadMasters(withDevices: true),
      // The window saved with the settlement is the Super Admin's own, so the
      // one previewed here is the one that will be recorded on save.
      SolarSettlementService.touWindow(uid),
    ]);
    if (!mounted) return;
    final load = results[0] as ConfigLoadResult;
    setState(() {
      _saved = load.config;
      _draft = load.config;
      _published = load.saved;
      _loadFailed = load.failed;
      _masters = results[1] as SettlementMasters;
      _tou = results[2] as TouWindow?;
      _takeVersion(load.config.latestVersion);
      _loading = false;
    });
    _syncDerived();
  }

  void _takeVersion(RateVersion? v) {
    if (v == null) {
      _version = 1;
      _effectiveFrom = _thisMonth();
      _peak = const RateTier();
      _offPeak = const RateTier();
      return;
    }
    _version = v.version;
    _effectiveFrom = v.effectiveFrom;
    _peak = v.peak;
    _offPeak = v.offPeak;
  }

  void _update(SettlementConfig next) {
    setState(() => _draft = next);
    _syncDerived();
  }

  /// Refetches the TNB rates and the preview only when something they depend
  /// on changed. Renaming a card label must not trigger thirty hourly
  /// requests.
  void _syncDerived() {
    final meter = SettlementSetupResolver.tnbMeterFor(_draft, _masters);
    final tnbKey = '${meter?.id}|${meter?.tariffCategoryId}';
    if (tnbKey != _tnbKey) {
      _tnbKey = tnbKey;
      _refreshTnb(meter?.tariffCategoryId.trim() ?? '');
    }
    final previewKey = [
      _draft.plantId,
      _draft.supplierPlantId,
      _draft.receiverPlantId,
      _draft.generationMeterId,
      _draft.sendMeterId,
      _draft.receiveMeterId,
      _draft.basis.name,
      _draft.missingFill.name,
    ].join('|');
    if (previewKey != _previewKey) {
      _previewKey = previewKey;
      _refreshPreview();
    }
  }

  Future<void> _refreshTnb(String categoryId) async {
    final token = ++_tnbToken;
    setState(() => _tnbLoading = true);
    final rates = await SettlementConfigService.tnbRates(categoryId);
    if (!mounted || token != _tnbToken) return;
    setState(() {
      _tnb = rates;
      _tnbLoading = false;
    });
  }

  Future<void> _refreshPreview() async {
    final token = ++_previewToken;
    final setup = SettlementSetupResolver.resolve(_draft, _masters);
    if (!setup.hasAgreement) {
      setState(() {
        _preview = null;
        _previewLoading = false;
      });
      return;
    }
    setState(() => _previewLoading = true);
    final inputs = SettlementInputs(
      month: _thisMonth(),
      supplier: setup.supplier!,
      receiver: setup.receiver!,
      splitMeterId: _draft.basis == SettlementBasis.sendSide
          ? _draft.sendMeterId
          : _draft.receiveMeterId,
      receiveMeterId: _draft.receiveMeterId,
      tou: _tou,
      missingFill: _draft.missingFill,
    );
    final totals = await SettlementLoader.loadTotals(inputs);
    if (!mounted || token != _previewToken) return;
    setState(() => _preview = totals);
    final done = await SettlementLoader.refineTouSplit(
      totals,
      inputs,
      isCancelled: () => !mounted || token != _previewToken,
      onProgress: (partial) {
        if (mounted && token == _previewToken) {
          setState(() => _preview = partial);
        }
      },
    );
    if (!mounted || token != _previewToken) return;
    setState(() {
      _preview = done;
      _previewLoading = false;
    });
  }

  // ── Draft, versions and saving ────────────────────────────────────────────

  int get _publishedVersion => _saved.latestVersion?.version ?? 0;

  String get _plantName => _masters.plantName(_draft.plantId);

  String _versionLabel(int v) => SettlementPricing.versionLabel(_plantName, v);

  /// The draft with the version being edited written into its version list.
  /// [stamp] adds who saved it and when, and records the ToU owner.
  SettlementConfig _composed({bool stamp = false}) {
    final uid = AppStateNotifier.instance.uid ?? '';
    final who = AppStateNotifier.instance.userEmail ??
        AppStateNotifier.instance.userName ??
        '';
    final now = DateTime.now();
    RateVersion? existing;
    for (final v in _draft.versions) {
      if (v.version == _version) existing = v;
    }
    final entry = RateVersion(
      version: _version,
      effectiveFrom: _effectiveFrom,
      peak: _peak,
      offPeak: _offPeak,
      savedAt: stamp ? now : existing?.savedAt,
      savedBy: stamp ? who : (existing?.savedBy ?? ''),
    );
    final versions = [
      for (final v in _draft.versions)
        if (v.version != _version) v,
      entry,
    ]..sort((a, b) => a.version - b.version);
    return _draft.copyWith(
      versions: versions,
      touSourceUid: stamp && uid.isNotEmpty ? uid : null,
      updatedBy: stamp ? who : null,
      updatedAt: stamp ? now : null,
    );
  }

  /// A config minus who-and-when, so saving the same terms twice is not a
  /// change.
  static String _fingerprint(SettlementConfig c) {
    final json = c.toJson()
      ..remove('updatedBy')
      ..remove('updatedAt')
      ..remove('touSourceUid');
    json['versions'] = [
      for (final v in c.versions)
        v.toJson()
          ..remove('savedAt')
          ..remove('savedBy'),
    ];
    return jsonEncode(json);
  }

  bool get _hasUnsaved => _published
      ? _fingerprint(_composed()) != _fingerprint(_saved)
      : _peak.resolve(1) > 0 || _offPeak.resolve(1) > 0;

  String? _validate() {
    if (_loadFailed) {
      return 'The saved settings could not be read. Reload the page before '
          'saving, so they are not replaced by defaults.';
    }
    final setup = SettlementSetupResolver.resolve(_draft, _masters);
    if (!setup.hasAgreement) {
      return 'Pick two different blocks as supplier and receiver.';
    }
    if (_draft.generationMeterId.isEmpty || _draft.sendMeterId.isEmpty) {
      return 'Pick the solar generation meter and the send-side meter.';
    }
    if (_draft.basis == SettlementBasis.receiveSide &&
        _draft.receiveMeterId.isEmpty) {
      return 'A receive-side basis needs a receive-side meter.';
    }
    if (_peak.resolve(_tnb.peak) <= 0 || _offPeak.resolve(_tnb.offPeak) <= 0) {
      return 'Both tiers need a price above zero. A TNB × factor tier also '
          'needs a TNB rate to multiply.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_isSuperAdmin || _saving) return;
    final problem = _validate();
    if (problem != null) {
      _snack(problem, error: true);
      return;
    }
    setState(() => _saving = true);
    final next = _composed(stamp: true);
    final ok = await SettlementConfigService.save(next);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _saved = next;
        _draft = next;
        _published = true;
      }
    });
    _snack(
      ok
          ? 'Saved — ${_versionLabel(_version)} is published.'
          : 'The settings could not be saved. Nothing was changed.',
      error: !ok,
    );
  }

  Future<void> _editVersion({required bool createNew}) async {
    final choice = await VersionEditDialog.show(
      context,
      publishedVersion: _publishedVersion,
      draftVersion: _version,
      effectiveFrom: _effectiveFrom,
      createNew: createNew,
      plantName: _plantName,
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (choice.version != _version) {
        // Returning to a saved version shows its own prices; a new version
        // starts from the prices on screen.
        for (final v in _saved.versions) {
          if (v.version == choice.version) {
            _peak = v.peak;
            _offPeak = v.offPeak;
          }
        }
      }
      _version = choice.version;
      _effectiveFrom = choice.effectiveFrom;
    });
  }

  Future<void> _leave(String routeName) async {
    if (_hasUnsaved) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text(
              'The changes on this page have not been saved and will be lost.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep editing')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard')),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) context.goNamed(routeName);
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor:
          error ? const Color(0xFF7F1D1D) : const Color(0xFF065F46),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _toggle(String key) => setState(
      () => _collapsed.contains(key) ? _collapsed.remove(key) : _collapsed.add(key));

  String _window({required bool peak}) {
    final t = _tou;
    if (t == null) return '';
    String hhmm(double h) {
      final hours = h.floor();
      final mins = ((h - hours) * 60).round();
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    }

    return peak
        ? '${hhmm(t.startHour)}–${hhmm(t.endHour)} · '
            '${TouReferenceStrip.daysLabel(t.days)}'
        : 'all other times';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    if (!_isSuperAdmin) return _denied(p);

    return Scaffold(
      backgroundColor: p.page,
      body: LayoutBuilder(builder: (context, c) {
        final gutter =
            c.maxWidth < 620 ? 12.0 : (c.maxWidth < 1000 ? 18.0 : 24.0);
        // Room under the last panel for the pinned bar, which is taller once
        // it wraps.
        final reserve = c.maxWidth < 1100 ? 200.0 : 110.0;
        return Stack(children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(gutter, 20, gutter, reserve),
              child: _content(p),
            ),
          ),
          if (!_loading)
            Positioned(left: 0, right: 0, bottom: 0, child: _impactBar()),
        ]);
      }),
    );
  }

  Widget _content(SettlementPalette p) {
    const gap = SizedBox(height: 14);
    final supplierName = SettlementSetupResolver.blockName(
        _draft.supplierPlantId, _draft.plantId, _masters);
    final receiverName = SettlementSetupResolver.blockName(
        _draft.receiverPlantId, _draft.plantId, _masters);

    final pv = _preview;
    final peakKwh = pv == null ? null : SettlementCalculator.peakKwh(pv);
    final offPeakKwh = pv == null ? null : SettlementCalculator.offPeakKwh(pv);
    double? money(double? kwh, double rate) =>
        kwh == null || rate <= 0 ? null : kwh * rate;
    final draftPeakRm = money(peakKwh, _peak.resolve(_tnb.peak));
    final draftOffPeakRm = money(offPeakKwh, _offPeak.resolve(_tnb.offPeak));

    final saved = _saved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingHeader(
          versionLabel: _versionLabel(_version),
          effectiveFrom: _effectiveFrom,
          published: _published && _publishedVersion >= _version,
          dirty: _hasUnsaved,
          saving: _saving,
          onBack: () => _leave('SolarSettlement'),
          onHistory: saved.versions.isEmpty
              ? null
              : () => VersionHistoryDialog.show(context,
                  versions: saved.versions, plantName: _plantName),
          onNewVersion: () => _editVersion(createNew: true),
          onEditVersion: () => _editVersion(createNew: false),
          onSave: _loading ? null : _save,
          updatedLine: saved.updatedAt == null
              ? ''
              : 'Last saved ${SettlementFormat.dayLabel(saved.updatedAt!.toLocal())}'
                  '${saved.updatedBy.isEmpty ? '' : ' by ${saved.updatedBy}'}',
        ),
        const SizedBox(height: 18),
        if (_loadFailed) ...[
          Container(
            decoration: p.cardDecoration(accent: SettlementColors.amber),
            clipBehavior: Clip.antiAlias,
            child: const SettingNote(
              tone: NoteTone.amber,
              text: 'The saved settings could not be read, so defaults are '
                  'showing. Saving is blocked until the page is reloaded.',
            ),
          ),
          gap,
        ],
        if (_loading)
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: p.cardDecoration(),
            child: CircularProgressIndicator(color: p.accent),
          )
        else ...[
          const SettingLegend(),
          gap,
          SupplyAgreementPanel(
            config: _draft,
            masters: _masters,
            onChanged: _update,
            collapsed: _collapsed.contains('agreement'),
            onToggle: () => _toggle('agreement'),
          ),
          gap,
          KpiStripPanel(
            config: _draft,
            masters: _masters,
            receiverName: receiverName,
            touConfigured: _tou != null,
            priced: draftPeakRm != null || draftOffPeakRm != null ||
                (_peak.resolve(_tnb.peak) > 0 &&
                    _offPeak.resolve(_tnb.offPeak) > 0),
            preview: KpiPreview(
              generation:
                  pv == null ? null : SettlementCalculator.solarGenerated(pv),
              supplied: pv == null ? null : SettlementCalculator.supplied(pv),
              peak: peakKwh,
              offPeak: offPeakKwh,
              total: draftPeakRm == null && draftOffPeakRm == null
                  ? null
                  : (draftPeakRm ?? 0) + (draftOffPeakRm ?? 0),
              loading: _previewLoading,
            ),
            onChanged: _update,
            collapsed: _collapsed.contains('kpi'),
            onToggle: () => _toggle('kpi'),
          ),
          gap,
          TouReferenceStrip(
            tou: _tou,
            onEdit: () => _leave('EnergySystemSettings'),
          ),
          gap,
          SettlementRatePanel(
            peak: _peak,
            offPeak: _offPeak,
            tnb: _tnb,
            peakWindow: _window(peak: true),
            offPeakWindow: _window(peak: false),
            supplierName: supplierName,
            receiverName: receiverName,
            onPeak: (t) => setState(() => _peak = t),
            onOffPeak: (t) => setState(() => _offPeak = t),
            collapsed: _collapsed.contains('rate'),
            onToggle: () => _toggle('rate'),
          ),
          gap,
          TnbReferencePanel(
            config: _draft,
            masters: _masters,
            tnb: _tnb,
            loading: _tnbLoading,
            onChanged: _update,
            onOpenMeters: () => _leave('GfsTnbMeter'),
            onOpenBilling: () => _leave('MasterBillingConfig'),
            collapsed: _collapsed.contains('tnb'),
            onToggle: () => _toggle('tnb'),
          ),
          gap,
          LedgerRulesPanel(
            config: _draft,
            masters: _masters,
            supplierName: supplierName,
            receiverName: receiverName,
            sentKwh: pv == null ? null : SettlementCalculator.supplied(pv),
            receivedKwh: pv?.receivedKwh,
            loading: _previewLoading,
            onChanged: _update,
            collapsed: _collapsed.contains('ledger'),
            onToggle: () => _toggle('ledger'),
          ),
        ],
      ],
    );
  }

  Widget _impactBar() {
    final supplierName = SettlementSetupResolver.blockName(
        _draft.supplierPlantId, _draft.plantId, _masters);
    final receiverName = SettlementSetupResolver.blockName(
        _draft.receiverPlantId, _draft.plantId, _masters);
    final pv = _preview;
    final peakKwh = pv == null ? null : SettlementCalculator.peakKwh(pv);
    final offPeakKwh = pv == null ? null : SettlementCalculator.offPeakKwh(pv);
    double? money(double? kwh, double rate) =>
        kwh == null || rate <= 0 ? null : kwh * rate;

    final savedRates = _published
        ? SettlementPricing.ratesFor(_saved, _thisMonth(), _tnb)
        : null;
    final draftPeak = _peak.resolve(_tnb.peak);
    final draftOffPeak = _offPeak.resolve(_tnb.offPeak);
    final pass = SettlementPricing.passesGuardrail(_peak, _offPeak, _tnb);

    final String message;
    final bool ok;
    if (_loadFailed) {
      message = 'Saved settings could not be read — reload before saving.';
      ok = false;
    } else if (draftPeak <= 0 || draftOffPeak <= 0) {
      message = 'Enter a price for both tiers to publish '
          '${_versionLabel(_version)}.';
      ok = false;
    } else if (!pass) {
      message = 'A tier charges more than TNB — $receiverName would be worse '
          'off than buying from TNB in that window.';
      ok = false;
    } else if (_hasUnsaved) {
      message = 'Preview of unsaved changes. All tiers pass '
          '"$receiverName < TNB". Save to publish ${_versionLabel(_version)}.';
      ok = true;
    } else {
      message = '${_versionLabel(_version)} is published. All tiers pass '
          '"$receiverName < TNB".';
      ok = true;
    }

    return ImpactBar(
      title: 'Total settlement · ${SettlementFormat.monthLabel(_thisMonth())}'
          '${supplierName.isEmpty || receiverName.isEmpty ? '' : ' ($supplierName → $receiverName)'}',
      peakKwh: peakKwh,
      offPeakKwh: offPeakKwh,
      savedPeakRm: money(peakKwh, savedRates?.peakRmPerKwh ?? 0),
      draftPeakRm: money(peakKwh, draftPeak),
      savedOffPeakRm: money(offPeakKwh, savedRates?.offPeakRmPerKwh ?? 0),
      draftOffPeakRm: money(offPeakKwh, draftOffPeak),
      loading: _previewLoading && pv == null,
      message: message,
      messageOk: ok,
      saving: _saving,
      onSave: _save,
    );
  }

  Widget _denied(SettlementPalette p) => Scaffold(
        backgroundColor: p.page,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(28),
            decoration: p.cardDecoration(accent: SettlementColors.amber),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline,
                  size: 40, color: SettlementColors.amber),
              const SizedBox(height: 14),
              Text('Super Admin only',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 6),
              Text(
                'Solar Settlement settings decide what one block invoices '
                'another, so only a Super Admin can view or change them.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13.5, color: p.subText, height: 1.5),
              ),
              const SizedBox(height: 18),
              SettingButton(
                label: 'Back to Solar Settlement',
                icon: Icons.arrow_back,
                onTap: () => context.goNamed('SolarSettlement'),
              ),
            ]),
          ),
        ),
      );
}
