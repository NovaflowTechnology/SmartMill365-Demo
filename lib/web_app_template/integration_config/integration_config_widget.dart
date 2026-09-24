import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'integration_config_cubit.dart';
import 'integration_config_models.dart';
import 'package:smartmachine365/services/site_tenant.dart';
import 'add_client_dialog.dart';
import 'add_plant_dialog.dart';

class IntegrationConfigWidget extends StatefulWidget {
  const IntegrationConfigWidget({super.key});

  @override
  State<IntegrationConfigWidget> createState() => _IntegrationConfigWidgetState();
}

class _IntegrationConfigWidgetState extends State<IntegrationConfigWidget> {
  late final IntegrationConfigCubit _cubit;

  // Per-client form controllers keyed by clientId
  final Map<String, _ClientFormState> _forms = {};

  // Unsaved dirty flag
  bool _dirty = false;
  bool _deploying = false;
  int _deployStep = 0; // 0-3

  // Password/token visibility
  final Map<String, bool> _showSecret = {};

  // Collapsible section open state
  final Map<String, bool> _sectionOpen = {
    'stag': true,
    'health': true,
    'hist': true,
    'ck': true,
  };

  // Test connection result per client+type
  final Map<String, _ConnTestResult?> _testResults = {};

  @override
  void initState() {
    super.initState();
    _cubit = IntegrationConfigCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    for (final f in _forms.values) {
      f.dispose();
    }
    super.dispose();
  }

  _ClientFormState _formFor(ClientConfig c) {
    return _forms.putIfAbsent(c.id, () => _ClientFormState.from(c));
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────
  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  FlutterFlowTheme get _t => FlutterFlowTheme.of(context);
  Color get _borderCol => _isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2A45);
  Color get _subText => _isLight ? const Color(0xFF64748B) : _t.secondaryText;
  Color get _accent => _t.primary;
  Color get _cyan => _t.secondary;
  Color get _green => _t.success;
  Color get _red => _t.error;
  Color get _amber => _t.warning;

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _snack(String msg, {required bool ok, bool warn = false}) {
    final color = warn ? _amber : (ok ? _green : _red);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: _t.primaryText)),
      backgroundColor: _t.primaryBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.4))),
      duration: Duration(seconds: ok ? 2 : 3),
    ));
  }

  // ── Deploy animation ──────────────────────────────────────────────────────
  Future<void> _runDeploy(ClientConfig client, _ClientFormState form) async {
    if (client.influx.host.isEmpty && form.influxHost.text.isEmpty) {
      _snack('InfluxDB host is required', ok: false);
      return;
    }
    setState(() {
      _dirty = false;
      _deploying = true;
      _deployStep = 0;
    });

    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _deployStep = i + 1);
    }

    final updated = _applyForm(client, form);
    try {
      // Always save token/password if field is not empty (not just when changed)
      if (form.influxToken.text.isNotEmpty) {
        await _cubit.saveInfluxToken(client.id, form.influxToken.text.trim());
      }
      if (form.mysqlPw.text.isNotEmpty) {
        await _cubit.saveMysqlPassword(client.id, form.mysqlPw.text);
      }
      if (form.fbSecret.text.isNotEmpty) {
        await _cubit.saveFirebaseSecret(client.id, form.fbSecret.text.trim());
      }
      await _cubit.save(updated);
      if (mounted) _snack('Saved successfully', ok: true);
    } catch (e) {
      if (mounted) _snack('Save failed: $e', ok: false);
    }

    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) setState(() => _deploying = false);
  }

  ClientConfig _applyForm(ClientConfig c, _ClientFormState f) {
    return c.copyWith(
      influx: c.influx.copyWith(
        host: f.influxHost.text.trim(),
        org: f.influxOrg.text.trim(),
        bucketRaw: f.influxBucketRaw.text.trim(),
        bucketPredictions: f.influxBucketPred.text.trim(),
        bucketOee: f.influxBucketOee.text.trim(),
        tokenSet: f.influxTokenChanged ? f.influxToken.text.isNotEmpty : c.influx.tokenSet,
        token: f.influxTokenChanged ? f.influxToken.text.trim() : c.influx.token,
        retryAttempts: f.influxRetryAttempts,
        retryInterval: f.influxRetryInterval,
        onFailure: f.influxOnFailure,
        measurement: f.influxMeasurement.text.trim().isEmpty ? 'power_meter' : f.influxMeasurement.text.trim(),
        deviceIdTag: f.influxDeviceIdTag.text.trim().isEmpty ? 'device_name' : f.influxDeviceIdTag.text.trim(),
        deviceTypeTag: f.influxDeviceTypeTag.text.trim(),
        deviceTypeVal: f.influxDeviceTypeVal.text.trim(),
      ),
      mysql: c.mysql.copyWith(
        host: f.mysqlHost.text.trim(),
        port: f.mysqlPort.text.trim(),
        database: f.mysqlDb.text.trim(),
        username: f.mysqlUser.text.trim(),
        passwordSet: f.mysqlPwChanged ? f.mysqlPw.text.isNotEmpty : c.mysql.passwordSet,
        retryAttempts: f.mysqlRetryAttempts,
        retryInterval: f.mysqlRetryInterval,
        onFailure: f.mysqlOnFailure,
      ),
      firebase: c.firebase.copyWith(
        projectId: f.fbProjectId.text.trim(),
        secretSet: f.fbSecret.text.isNotEmpty ? true : c.firebase.secretSet,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<IntegrationConfigCubit, IntegrationConfigState>(
        listenWhen: (_, s) => s is IntegrationConfigSaved || s is IntegrationConfigError || s is IntegrationConfigConnTested,
        listener: (ctx, st) {
          if (st is IntegrationConfigSaved) {
            _snack('Config saved & deployed successfully', ok: true);
          } else if (st is IntegrationConfigError) {
            _snack(st.message, ok: false);
          } else if (st is IntegrationConfigConnTested) {
            final who = st.connType == 'influx' ? 'InfluxDB' : 'MySQL';
            _snack(
              st.ok ? '$who connected — ${st.ms}ms' : '$who connection failed — check host & credentials',
              ok: st.ok,
            );
            _testResults['${st.selectedId}_${st.connType}'] = _ConnTestResult(ok: st.ok, ms: st.ms);
            setState(() {});
          }
        },
        builder: (ctx, st) {
          if (st is IntegrationConfigLoading || st is IntegrationConfigInitial) {
            return _loading();
          }
          if (st is IntegrationConfigError && (st is! IntegrationConfigConnTested)) {
            return _errorView(st.message);
          }

          // All states that carry clients
          List<ClientConfig> clients = [];
          String selectedId = '';
          bool isTesting = false;
          String testingType = '';

          if (st is IntegrationConfigLoaded) {
            clients = st.clients;
            selectedId = st.selectedId;
          } else if (st is IntegrationConfigSaving) {
            clients = st.clients;
            selectedId = st.selectedId;
          } else if (st is IntegrationConfigSaved) {
            clients = st.clients;
            selectedId = st.selectedId;
          } else if (st is IntegrationConfigTestingConn) {
            clients = st.clients;
            selectedId = st.selectedId;
            isTesting = true;
            testingType = st.connType;
          } else if (st is IntegrationConfigConnTested) {
            clients = st.clients;
            selectedId = st.selectedId;
          } else if (st is IntegrationConfigError) {
            return _errorView(st.message);
          }

          final selected = clients.where((c) => c.id == selectedId).firstOrNull;

          return Scaffold(
            backgroundColor: _t.primaryBackground,
            body: Column(
              children: [
                // ── Page header ──────────────────────────────────────────────
                _pageHeader(clients),

                // ── SA banner ────────────────────────────────────────────────
                _saBanner(),

                // ── Deploy bar ───────────────────────────────────────────────
                if (_deploying) _deployBar(),

                // ── Unsaved banner ───────────────────────────────────────────
                if (_dirty && !_deploying) _unsavedBanner(selected, clients, selectedId),

                // ── Body ─────────────────────────────────────────────────────
                Expanded(
                  child: clients.isEmpty
                      ? _emptyState()
                      : Row(
                          children: [
                            // Client tab strip
                            _clientStrip(clients, selectedId),

                            // Main content
                            Expanded(
                              child: selected == null
                                  ? _emptyState()
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                                      child: _clientContent(selected, isTesting, testingType),
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Page header ────────────────────────────────────────────────────────────
  Widget _pageHeader(List<ClientConfig> clients) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: _t.primaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(children: [
            _breadCrumb('Settings'),
            const Icon(Icons.chevron_right, size: 14),
            _breadCrumb('System'),
            const Icon(Icons.chevron_right, size: 14),
            Text('Integration Config', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _t.primaryText)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _accent.withOpacity(0.25)),
              ),
              child: Icon(Icons.cable_rounded, color: _accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Integration Config',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: _t.primaryText)),
                  Text('Configure InfluxDB & MySQL data source connections per client domain.',
                      style: GoogleFonts.poppins(fontSize: 12, color: _subText, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(children: [
              _ghostBtn(label: '⚡  Test All', onTap: () => _testAll(clients), t: _t, isLight: _isLight),
              // A customer site manages only its own client, so it cannot add others.
              if (SiteTenant.lockedClientId == null) ...[
                const SizedBox(width: 8),
                _primaryBtn(label: '＋  Add Client', onTap: () => _showAddDialog(), t: _t, isLight: _isLight),
              ],
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _breadCrumb(String label) => Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
      );

  // ── SA banner ──────────────────────────────────────────────────────────────
  Widget _saBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.lock_outline_rounded, size: 15, color: _accent),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 12, color: _accent.withOpacity(0.9), height: 1.5),
              children: [
                TextSpan(text: 'Super Admin Only', style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(
                    text: ' — Hidden from all other roles. Changes affect live data routing for all widgets immediately after Save & Deploy.'),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Deploy bar ─────────────────────────────────────────────────────────────
  Widget _deployBar() {
    final steps = [
      'Saving config',
      'Updating Data Query Service',
      'Verifying connections',
      'Live ✓',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _t.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderCol),
      ),
      child: Row(children: [
        Text('Deploying', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _t.primaryText)),
        const SizedBox(width: 12),
        ...List.generate(steps.length, (i) {
          final done = _deployStep > i;
          final running = _deployStep == i;
          final color = done ? _green : (running ? _cyan : _subText);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('›', style: TextStyle(color: _subText, fontSize: 12)),
              ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: running ? [BoxShadow(color: _cyan.withOpacity(0.5), blurRadius: 6)] : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(steps[i], style: GoogleFonts.poppins(fontSize: 10.5, color: color, fontWeight: FontWeight.w500)),
          ]);
        }),
      ]),
    );
  }

  // ── Unsaved banner ─────────────────────────────────────────────────────────
  Widget _unsavedBanner(ClientConfig? selected, List<ClientConfig> clients, String selectedId) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _amber.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, size: 15, color: _amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Unsaved changes.', style: GoogleFonts.poppins(fontSize: 12, color: _amber, fontWeight: FontWeight.w500)),
        ),
        _smallBtn('Discard', _amber, () {
          setState(() => _dirty = false);
          if (selected != null) {
            _forms[selected.id] = _ClientFormState.from(selected);
          }
        }),
      ]),
    );
  }

  // ── Client strip (vertical tabs on left) ───────────────────────────────────
  Widget _clientStrip(List<ClientConfig> clients, String selectedId) {
    return Container(
      width: 200,
      color: _t.primaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text('CLIENT DOMAIN', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: _subText)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ...clients.map((c) {
                  final isSelected = c.id == selectedId;
                  final dot = c.influx.connected && c.mysql.connected
                      ? _green
                      : c.influx.host.isNotEmpty || c.mysql.host.isNotEmpty
                          ? _amber
                          : _red;
                  return GestureDetector(
                    onTap: () {
                      if (_dirty) {
                        _snack('Save or discard changes first', ok: false, warn: true);
                        return;
                      }
                      _cubit.select(c.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _accent.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dot,
                            boxShadow: isSelected ? [BoxShadow(color: dot.withOpacity(0.5), blurRadius: 5)] : null,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? _accent : _t.primaryText)),
                              Text('(${c.code})', style: GoogleFonts.poppins(fontSize: 10, color: isSelected ? _accent.withOpacity(0.7) : _subText)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
                if (SiteTenant.lockedClientId == null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showAddDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderCol, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.add, size: 14, color: _subText),
                        const SizedBox(width: 6),
                        Text('Add Client', style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Client content ─────────────────────────────────────────────────────────
  Widget _clientContent(ClientConfig c, bool isTesting, String testingType) {
    final form = _formFor(c);
    final allOk = c.influx.connected && c.mysql.connected;
    final partial = !allOk && (c.influx.connected || c.mysql.connected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Client name / code header (editable) ─────────────────────────────
        Row(children: [
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(c.name,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _t.primaryText)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('(${c.code})', style: GoogleFonts.sourceCodePro(fontSize: 12, color: _subText)),
              ),
            ]),
          ),
          InkWell(
            onTap: () => _showEditClientDialog(c),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _t.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _t.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined, size: 12, color: _t.primary),
                const SizedBox(width: 4),
                Text('Edit', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _t.primary)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // ── Status alert ──────────────────────────────────────────────────
        _statusAlert(c, allOk, partial),
        const SizedBox(height: 16),

        // ── Stat cards ────────────────────────────────────────────────────
        _statCards(c, allOk, partial),
        const SizedBox(height: 16),

        // ── Connection cards ───────────────────────────────────────────────
        _EqualHeightPair(
          left: _influxCard(c, form, isTesting && testingType == 'influx'),
          right: _mysqlCard(c, form, isTesting && testingType == 'mysql'),
        ),
        const SizedBox(height: 14),

        // ── Firebase API Deploy ────────────────────────────────────────────
        _firebaseCard(c, form),
        const SizedBox(height: 14),

        // ── Site tag mapping ───────────────────────────────────────────────
        _collapsibleSection(
          id: 'stag',
          icon: Icons.sell_outlined,
          title: 'InfluxDB Site Tag → Plant Mapping',
          meta: '${c.siteTags.length} mapping${c.siteTags.length != 1 ? 's' : ''} · Required for Device Discovery',
          child: _siteTagSection(c, form),
        ),
        const SizedBox(height: 10),

        // ── Channel mapping ────────────────────────────────────────────────
        _collapsibleSection(
          id: 'channel',
          icon: Icons.cable_rounded,
          title: 'Channel Mapping',
          meta:
              '${c.channelMappings.isEmpty ? ChannelMapping.defaults.length : c.channelMappings.length} channels · SF365 field → InfluxDB field key',
          child: _channelMappingSection(c, form),
        ),
        const SizedBox(height: 10),

        // ── Health check ───────────────────────────────────────────────────
        _collapsibleSection(
          id: 'health',
          icon: Icons.monitor_heart_outlined,
          title: 'Auto Health Check',
          meta: 'Every 1 min · ${allOk ? 'All OK' : 'Issues detected'}',
          metaColor: allOk ? _green : _red,
          child: _healthSection(c),
        ),
        const SizedBox(height: 10),

        // ── Change history ─────────────────────────────────────────────────
        _collapsibleSection(
          id: 'hist',
          icon: Icons.history_rounded,
          title: 'Change History',
          meta: '${c.history.length} record${c.history.length != 1 ? 's' : ''}',
          child: _historySection(c),
        ),
        const SizedBox(height: 10),

        // ── Setup checklist ────────────────────────────────────────────────
        _collapsibleSection(
          id: 'ck',
          icon: Icons.checklist_rounded,
          title: 'Setup Checklist',
          meta: '${c.checklist.pct}% complete',
          child: _checklistSection(c),
        ),
        const SizedBox(height: 20),

        // ── Footer actions ─────────────────────────────────────────────────
        _footer(c, form),
      ],
    );
  }

  // ── Status alert ───────────────────────────────────────────────────────────
  Widget _statusAlert(ClientConfig c, bool allOk, bool partial) {
    final color = allOk ? _green : (partial ? _amber : _red);
    final icon = allOk ? Icons.check_circle_outline : Icons.warning_amber_rounded;
    final msg = allOk
        ? 'All connections active for ${c.name}. Data Query Service routing live via ${c.domain}.'
        : partial
            ? 'One or more connections not configured for ${c.name}. Complete setup below.'
            : 'No connections configured for ${c.name}. Set up InfluxDB and MySQL to activate all widgets.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg, style: GoogleFonts.poppins(fontSize: 12, color: color, height: 1.5)),
        ),
      ]),
    );
  }

  // ── Stat cards ─────────────────────────────────────────────────────────────
  Widget _statCards(ClientConfig c, bool allOk, bool partial) {
    final statusColor = allOk ? _green : (partial ? _amber : _red);
    final pct = c.checklist.pct;
    final pctColor = pct == 100 ? _green : (pct > 50 ? _amber : _red);
    final planColor = c.plan == 'Enterprise'
        ? _accent
        : c.plan == 'Basic'
            ? _cyan
            : _amber;

    return Row(children: [
      Expanded(
          child: _statCard(
        label: 'STATUS',
        valueWidget: Text(
          allOk
              ? '● All Connected'
              : partial
                  ? '◑ Partial Setup'
                  : '✕ Not Connected',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
        ),
        sub: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: planColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: planColor.withOpacity(0.25)),
          ),
          child: Text(c.plan, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: planColor)),
        ),
        borderColor: statusColor.withOpacity(0.2),
      )),
      const SizedBox(width: 10),
      Expanded(
          child: _statCard(
        label: 'CLIENT DOMAIN',
        valueWidget:
            Text(c.domain, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _cyan), overflow: TextOverflow.ellipsis),
        sub: _smallBtn('↗ Open Portal', _cyan, () {}),
      )),
      const SizedBox(width: 10),
      Expanded(
          child: _statCard(
        label: 'PRIMARY CONTACT',
        valueWidget: Text(c.contact, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _t.primaryText)),
        sub: Text('${c.plants.length} plant${c.plants.length != 1 ? 's' : ''}: ${c.plants.take(2).join(', ')}${c.plants.length > 2 ? '…' : ''}',
            style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
      )),
      const SizedBox(width: 10),
      Expanded(
          child: _statCard(
        label: 'SETUP PROGRESS',
        valueWidget: RichText(
          text: TextSpan(children: [
            TextSpan(text: '$pct', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: pctColor)),
            TextSpan(text: '%', style: GoogleFonts.poppins(fontSize: 13, color: _subText)),
          ]),
        ),
        sub: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: _borderCol,
            color: pctColor,
            minHeight: 4,
          ),
        ),
      )),
    ]);
  }

  Widget _statCard({
    required String label,
    required Widget valueWidget,
    required Widget sub,
    Color? borderColor,
  }) {
    return CardWidget(
      glowColor: borderColor,
      topPadMultiplier: 1.0,
      bottomPadMultiplier: 1.0,
      builder: (ctx, sizing) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _subText)),
            const SizedBox(height: 8),
            valueWidget,
            const SizedBox(height: 8),
            sub,
          ],
        ),
      ),
    );
  }

  // ── InfluxDB card ──────────────────────────────────────────────────────────
  Widget _influxCard(ClientConfig c, _ClientFormState f, bool isTesting) {
    final inf = c.influx;
    final dotColor = inf.connected ? _green : (inf.host.isNotEmpty ? _red : _subText);
    final statusLabel = inf.connected ? 'Connected' : (inf.host.isNotEmpty ? 'Error' : 'Not Set');
    final testKey = '${c.id}_influx';
    final testResult = _testResults[testKey];

    return _connCard(
      icon: Icons.show_chart_rounded,
      title: 'InfluxDB Connection',
      subtitle: inf.connected ? inf.host : 'Not configured',
      dotColor: dotColor,
      statusLabel: statusLabel,
      lastCheck: inf.lastCheck,
      latency: inf.latencyMs,
      borderColor: inf.connected
          ? _green.withOpacity(0.2)
          : inf.host.isNotEmpty
              ? _red.withOpacity(0.2)
              : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formField(f.influxHost, 'Host / Endpoint *', 'https://influx.yourcompany.com'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField(f.influxOrg, 'Organisation *', 'your-org')),
            const SizedBox(width: 10),
            Expanded(child: _formField(f.influxBucketRaw, 'Bucket — energy_raw *', 'energy_raw')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField(f.influxBucketPred, 'Bucket — predictions', 'energy_predictions')),
            const SizedBox(width: 10),
            Expanded(child: _formField(f.influxBucketOee, 'Bucket — OEE', 'oee_raw')),
          ]),
          const SizedBox(height: 10),
          _secretField(
            label: 'API Token *',
            controller: f.influxToken,
            isSet: inf.tokenSet,
            showKey: '${c.id}_influxToken',
            onUnlock: () {
              setState(() {
                f.influxTokenChanged = true;
                f.influxToken.text = '';
              });
              _markDirty();
            },
          ),
          const SizedBox(height: 12),
          _retryRow(
            attempts: f.influxRetryAttempts,
            interval: f.influxRetryInterval,
            onFailure: f.influxOnFailure,
            onAttemptsChanged: (v) => setState(() {
              f.influxRetryAttempts = v;
              _markDirty();
            }),
            onIntervalChanged: (v) => setState(() {
              f.influxRetryInterval = v;
              _markDirty();
            }),
            onFailureChanged: (v) => setState(() {
              f.influxOnFailure = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField(f.influxMeasurement, 'Measurement', 'power_meter')),
            const SizedBox(width: 10),
            Expanded(child: _formField(f.influxDeviceIdTag, 'Device ID Tag', 'device_name')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField(f.influxDeviceTypeTag, 'Device Type Tag (optional)', 'device_type')),
            const SizedBox(width: 10),
            Expanded(child: _formField(f.influxDeviceTypeVal, 'Device Type Value (optional)', 'energy_meter')),
          ]),
          const SizedBox(height: 12),
          if (testResult != null) _testResultBadge(testResult),
          if (testResult != null) const SizedBox(height: 8),
          Row(children: [
            isTesting
                ? _loadingBtn('Testing…')
                : _secondaryBtn(
                    label: '⚡  Test Connection',
                    onTap: () {
                      _testResults.remove(testKey);
                      _cubit.testConnection(_applyForm(c, f), 'influx');
                    }),
            if (inf.connected) ...[
              const SizedBox(width: 8),
              _ghostBtn(
                  label: '↺ Re-test',
                  onTap: () {
                    _testResults.remove(testKey);
                    _cubit.testConnection(_applyForm(c, f), 'influx');
                  },
                  t: _t,
                  isLight: _isLight),
            ],
          ]),
        ],
      ),
    );
  }

  // ── MySQL card ─────────────────────────────────────────────────────────────
  Widget _mysqlCard(ClientConfig c, _ClientFormState f, bool isTesting) {
    final mys = c.mysql;
    final dotColor = mys.connected ? _green : (mys.host.isNotEmpty ? _red : _subText);
    final statusLabel = mys.connected ? 'Connected' : (mys.host.isNotEmpty ? 'Error' : 'Not Set');
    final testKey = '${c.id}_mysql';
    final testResult = _testResults[testKey];

    return _connCard(
      icon: Icons.storage_rounded,
      title: 'MySQL Connection',
      subtitle: mys.connected ? '${mys.host} · ${mys.database}' : 'Not configured',
      dotColor: dotColor,
      statusLabel: statusLabel,
      lastCheck: mys.lastCheck,
      latency: mys.latencyMs,
      borderColor: mys.connected
          ? _green.withOpacity(0.2)
          : mys.host.isNotEmpty
              ? _red.withOpacity(0.2)
              : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _formField(f.mysqlHost, 'Host *', 'mysql.yourcompany.com')),
            const SizedBox(width: 10),
            SizedBox(width: 90, child: _formField(f.mysqlPort, 'Port', '3306')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField(f.mysqlDb, 'Database Name *', 'novaflow_clientcode')),
            const SizedBox(width: 10),
            Expanded(child: _formField(f.mysqlUser, 'Username *', 'novaflow_user')),
          ]),
          const SizedBox(height: 10),
          _secretField(
            label: 'Password *',
            controller: f.mysqlPw,
            isSet: mys.passwordSet,
            showKey: '${c.id}_mysqlPw',
            onUnlock: () {
              setState(() {
                f.mysqlPwChanged = true;
                f.mysqlPw.text = '';
              });
              _markDirty();
            },
          ),
          const SizedBox(height: 12),
          _retryRow(
            attempts: f.mysqlRetryAttempts,
            interval: f.mysqlRetryInterval,
            onFailure: f.mysqlOnFailure,
            onAttemptsChanged: (v) => setState(() {
              f.mysqlRetryAttempts = v;
              _markDirty();
            }),
            onIntervalChanged: (v) => setState(() {
              f.mysqlRetryInterval = v;
              _markDirty();
            }),
            onFailureChanged: (v) => setState(() {
              f.mysqlOnFailure = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 12),
          if (testResult != null) _testResultBadge(testResult),
          if (testResult != null) const SizedBox(height: 8),
          Row(children: [
            isTesting
                ? _loadingBtn('Testing…')
                : _secondaryBtn(
                    label: '⚡  Test Connection',
                    onTap: () {
                      _testResults.remove(testKey);
                      _cubit.testConnection(
                        _applyForm(c, f),
                        'mysql',
                        mysqlPassword: f.mysqlPw.text,
                      );
                    }),
            if (mys.connected) ...[
              const SizedBox(width: 8),
              _ghostBtn(
                  label: '↺ Re-test',
                  onTap: () {
                    _testResults.remove(testKey);
                    _cubit.testConnection(
                      _applyForm(c, f),
                      'mysql',
                      mysqlPassword: f.mysqlPw.text,
                    );
                  },
                  t: _t,
                  isLight: _isLight),
            ],
          ]),
        ],
      ),
    );
  }

  // ── Firebase Config card ──────────────────────────────────────────────────
  Widget _firebaseCard(ClientConfig c, _ClientFormState f) {
    final fb = c.firebase;
    final isSet = fb.projectId.isNotEmpty;
    final dotColor = fb.secretSet ? _green : (isSet ? _amber : _subText);
    final statusLabel = fb.secretSet ? 'Connected' : (isSet ? 'No Secret' : 'Not Set');

    return _connCard(
      icon: Icons.local_fire_department_rounded,
      title: 'Firebase Connection',
      subtitle: isSet ? fb.projectId : 'Not configured',
      dotColor: dotColor,
      statusLabel: statusLabel,
      lastCheck: '',
      latency: null,
      borderColor: fb.secretSet
          ? _green.withOpacity(0.2)
          : isSet
              ? _amber.withOpacity(0.2)
              : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formField(f.fbProjectId, 'Firebase Project ID', 'e.g. thongguansf365'),
          const SizedBox(height: 12),
          _secretField(
            label: 'Service Account JSON',
            hint: 'Paste full JSON from Firebase Console → Service Accounts',
            controller: f.fbSecret,
            isSet: fb.secretSet,
            showKey: '${c.id}_fbSecret',
            onUnlock: () {
              setState(() {
                f.fbSecretChanged = true;
                f.fbSecret.text = '';
              });
              _markDirty();
            },
          ),
        ],
      ),
    );
  }

  Widget _connCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color dotColor,
    required String statusLabel,
    required String lastCheck,
    required int? latency,
    required Widget body,
    Color? borderColor,
  }) {
    return CardWidget(
      glowColor: borderColor,
      topPadMultiplier: 1.0,
      bottomPadMultiplier: 1.0,
      builder: (ctx, sizing) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dotColor.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 17, color: dotColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _t.primaryText)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: _subText), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 5)],
                ),
              ),
              const SizedBox(width: 6),
              Text(statusLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: dotColor)),
            ]),
          ]),
        ),
        Divider(height: 1, color: _borderCol),
        // Body
        Padding(
          padding: const EdgeInsets.all(14),
          child: body,
        ),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _t.primaryBackground,
            border: Border(top: BorderSide(color: _borderCol)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Row(children: [
            Text('Last check: $lastCheck', style: GoogleFonts.poppins(fontSize: 10, color: _subText)),
            const Spacer(),
            Text(
              latency != null ? '⚡ ${latency}ms' : '—',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: latency != null ? _green : _subText),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Form helpers ───────────────────────────────────────────────────────────
  Widget _formField(TextEditingController ctr, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _subText)),
        const SizedBox(height: 4),
        TextField(
          controller: ctr,
          onChanged: (_) => _markDirty(),
          style: GoogleFonts.poppins(fontSize: 12, color: _t.primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: _subText),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            filled: true,
            fillColor: _t.primaryBackground,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _borderCol),
              borderRadius: BorderRadius.circular(7),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _t.primary),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _secretField({
    required String label,
    required TextEditingController controller,
    required bool isSet,
    required String showKey,
    required VoidCallback onUnlock,
    String? hint,
  }) {
    final locked = isSet && !(_showSecret['${showKey}_unlocked'] ?? false);
    final visible = _showSecret[showKey] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _subText)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _green.withOpacity(0.25)),
            ),
            child: Text('AES-256', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w600, color: _green)),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: TextField(
              controller: locked ? (TextEditingController(text: '••••••••••••••••••••')) : controller,
              obscureText: !visible,
              readOnly: locked,
              onChanged: locked ? null : (_) => _markDirty(),
              style: GoogleFonts.poppins(fontSize: 12, color: locked ? _subText : _t.primaryText),
              decoration: InputDecoration(
                hintText: hint ?? 'Enter value…',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: _subText),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                filled: true,
                fillColor: locked ? _t.primaryBackground.withOpacity(0.7) : _t.primaryBackground,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _borderCol),
                  borderRadius: BorderRadius.circular(7),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _t.primary),
                  borderRadius: BorderRadius.circular(7),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 16, color: _subText),
                      onPressed: () => setState(() => _showSecret[showKey] = !visible),
                    ),
                    if (locked)
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 15, color: _subText),
                        onPressed: () {
                          _showSecret['${showKey}_unlocked'] = true;
                          onUnlock();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ]),
        if (locked)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('Encrypted at rest. Tap ✏️ to replace.', style: GoogleFonts.poppins(fontSize: 10, color: _amber)),
          ),
      ],
    );
  }

  Widget _retryRow({
    required int attempts,
    required int interval,
    required String onFailure,
    required void Function(int) onAttemptsChanged,
    required void Function(int) onIntervalChanged,
    required void Function(String) onFailureChanged,
  }) {
    return Row(children: [
      Expanded(
          child: _dropdownField(
        label: 'Max Retries',
        value: attempts,
        items: {1: '1 attempt', 2: '2 attempts', 3: '3 attempts', 5: '5 attempts'},
        onChanged: onAttemptsChanged,
      )),
      const SizedBox(width: 8),
      Expanded(
          child: _dropdownField(
        label: 'Retry Interval',
        value: interval,
        items: {5: '5s', 10: '10s', 30: '30s', 60: '60s'},
        onChanged: onIntervalChanged,
      )),
      const SizedBox(width: 8),
      Expanded(
          child: _dropdownFieldStr(
        label: 'On Failure',
        value: onFailure,
        items: {
          'last_value': 'Show last value',
          'error_state': 'Show error state',
          'hide_widget': 'Hide widget',
        },
        onChanged: onFailureChanged,
      )),
    ]);
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required void Function(T) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _subText, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _t.primaryBackground,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _borderCol),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              dropdownColor: _t.primaryBackground,
              style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText),
              items: items.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownFieldStr({
    required String label,
    required String value,
    required Map<String, String> items,
    required void Function(String) onChanged,
  }) =>
      _dropdownField<String>(label: label, value: value, items: items, onChanged: onChanged);

  Widget _testResultBadge(_ConnTestResult r) {
    final color = r.ok ? _green : _red;
    final icon = r.ok ? Icons.check_circle_outline : Icons.cancel_outlined;
    final msg = r.ok ? '✓ Connection successful — ${r.ms}ms' : '✕ Connection failed — check host and credentials';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(msg, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _loadingBtn(String label) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _t.primaryBackground,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _borderCol),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: _subText),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
      ]),
    );
  }

  // ── Plants section ────────────────────────────────────────────────────────
  // Plants belong UNDER an existing client — this is the correct way to
  // attach a factory to a client, instead of misusing "+ Add Client" (which
  // creates a brand new top-level client doc per factory).
  Widget _plantsSection(ClientConfig c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Plants', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _t.primaryText, letterSpacing: 0.5)),
          const Spacer(),
          InkWell(
            onTap: () async {
              final added = await showDialog<String>(
                context: context,
                builder: (_) => AddPlantDialog(clientName: c.name, existingPlants: c.plants),
              );
              if (added != null && added.isNotEmpty) {
                _cubit.save(c.copyWith(plants: [...c.plants, added]));
                _snack('Plant "$added" added to ${c.name}', ok: true);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _t.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _t.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 12, color: _t.primary),
                const SizedBox(width: 4),
                Text('Add Plant', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _t.primary)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: c.plants.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _t.primaryBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderCol),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p, style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText)),
                if (c.plants.length > 1) ...[
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () {
                      final newPlants = [...c.plants]..remove(p);
                      _cubit.save(c.copyWith(plants: newPlants));
                    },
                    child: Icon(Icons.close, size: 11, color: _subText),
                  ),
                ],
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Site tag section ───────────────────────────────────────────────────────
  Widget _siteTagSection(ClientConfig c, _ClientFormState f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _plantsSection(c),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.07),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _cyan.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: _cyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Map each InfluxDB site tag to its SF365 Plant. Device Discovery uses this to assign discovered devices to the correct plant.',
                style: GoogleFonts.poppins(fontSize: 11, color: _cyan.withOpacity(0.9), height: 1.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (c.siteTags.isNotEmpty) ...[
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _t.primaryBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              border: Border.all(color: _borderCol),
            ),
            child: Row(children: [
              Expanded(
                  child: Text('InfluxDB Site Tag',
                      style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _subText, letterSpacing: 0.7))),
              const SizedBox(width: 20),
              Expanded(
                  child:
                      Text('SF365 Plant', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _subText, letterSpacing: 0.7))),
              const SizedBox(width: 70),
            ]),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
              border: Border(
                left: BorderSide(color: _borderCol),
                right: BorderSide(color: _borderCol),
                bottom: BorderSide(color: _borderCol),
              ),
            ),
            child: Column(
              children: c.siteTags.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: i < c.siteTags.length - 1 ? Border(bottom: BorderSide(color: _borderCol)) : null,
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(s.tag, style: GoogleFonts.poppins(fontSize: 12, color: _cyan, fontWeight: FontWeight.w500)),
                    ),
                    Icon(Icons.arrow_forward, size: 14, color: _subText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _t.primaryBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _borderCol),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: c.plants.contains(s.plant) ? s.plant : (c.plants.isNotEmpty ? c.plants.first : null),
                            isExpanded: true,
                            isDense: true,
                            dropdownColor: _t.primaryBackground,
                            style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText),
                            items: c.plants
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText))))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              final newTags = [...c.siteTags];
                              newTags[i] = SiteTag(tag: s.tag, plant: v);
                              _cubit.save(c.copyWith(siteTags: newTags));
                              _markDirty();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Remove mapping',
                      child: InkWell(
                        onTap: () {
                          final newTags = [...c.siteTags]..removeAt(i);
                          _cubit.save(c.copyWith(siteTags: newTags));
                        },
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _red.withOpacity(0.25)),
                          ),
                          child: Icon(Icons.close, size: 13, color: _red),
                        ),
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Add new tag row
        Row(children: [
          Expanded(
            child: TextField(
              controller: f.newTagCtr,
              style: GoogleFonts.poppins(fontSize: 12, color: _t.primaryText),
              decoration: InputDecoration(
                hintText: 'InfluxDB site tag…',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: _subText),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                filled: true,
                fillColor: _t.primaryBackground,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderCol), borderRadius: BorderRadius.circular(7)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _t.primary), borderRadius: BorderRadius.circular(7)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 14, color: _subText),
          ),
          Expanded(
            child: c.plants.isEmpty
                ? Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration:
                        BoxDecoration(color: _t.primaryBackground, borderRadius: BorderRadius.circular(7), border: Border.all(color: _borderCol)),
                    child: Center(child: Text('No plants configured', style: GoogleFonts.poppins(fontSize: 11, color: _subText))))
                : Container(
                    decoration: BoxDecoration(
                      color: _t.primaryBackground,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _borderCol),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: f.newTagPlant.isNotEmpty && c.plants.contains(f.newTagPlant) ? f.newTagPlant : c.plants.first,
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: _t.primaryBackground,
                        style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText),
                        items: c.plants
                            .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText))))
                            .toList(),
                        onChanged: (v) => setState(() => f.newTagPlant = v ?? ''),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          _secondaryBtn(
            label: '+ Add',
            onTap: () {
              final tag = f.newTagCtr.text.trim();
              if (tag.isEmpty) return;
              if (c.siteTags.any((s) => s.tag == tag)) {
                _snack('Tag already mapped', ok: false, warn: true);
                return;
              }
              final plant = f.newTagPlant.isNotEmpty ? f.newTagPlant : (c.plants.isNotEmpty ? c.plants.first : '—');
              final newTags = [...c.siteTags, SiteTag(tag: tag, plant: plant)];
              f.newTagCtr.clear();
              _cubit.save(c.copyWith(siteTags: newTags));
            },
          ),
        ]),
      ],
    );
  }

  // ── Channel mapping section ────────────────────────────────────────────────
  Widget _channelMappingSection(ClientConfig c, _ClientFormState f) {
    final mappings = c.channelMappings.isEmpty ? ChannelMapping.defaults : c.channelMappings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _cyan.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 13, color: _cyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Map each SF365 standard field to its corresponding InfluxDB field key in your data source.',
                style: GoogleFonts.poppins(fontSize: 10, color: _cyan),
              ),
            ),
          ]),
        ),
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(flex: 3, child: Text('SF365 Field', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _subText))),
            Expanded(flex: 1, child: Text('Unit', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _subText))),
            Expanded(
                flex: 3, child: Text('InfluxDB Field Key', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _subText))),
          ]),
        ),
        // Mapping rows
        ...mappings.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final controller = TextEditingController(text: m.influxField);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _t.secondaryBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _borderCol),
                  ),
                  child: Text('${m.sf365Field}  ${m.label.isNotEmpty ? '· ${m.label}' : ''}',
                      style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: _t.secondaryBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _borderCol),
                  ),
                  child: Text(m.unit, style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: controller,
                  style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _borderCol)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _borderCol)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _cyan)),
                    fillColor: _t.secondaryBackground,
                    filled: true,
                  ),
                  onChanged: (v) {
                    final updated = List<ChannelMapping>.from(mappings);
                    updated[i] = m.copyWith(influxField: v.trim());
                    _cubit.save(c.copyWith(
                      channelMappings: updated,
                      checklist: c.checklist.copyWith(
                        channel: updated.any((ch) => ch.influxField.isNotEmpty),
                      ),
                    ));
                    _markDirty();
                  },
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        // Reset to defaults button
        TextButton.icon(
          onPressed: () {
            _cubit.save(c.copyWith(channelMappings: ChannelMapping.defaults));
            _markDirty();
          },
          icon: Icon(Icons.restart_alt_rounded, size: 14, color: _subText),
          label: Text('Reset to SF365 defaults', style: GoogleFonts.poppins(fontSize: 10, color: _subText)),
        ),
      ],
    );
  }

  // ── Health check section ───────────────────────────────────────────────────
  Widget _healthSection(ClientConfig c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _metricChip('Check Interval', '1 min'),
          const SizedBox(width: 10),
          _metricChip('Uptime 24h', c.influx.connected ? '99.8%' : '0.0%', color: c.influx.connected ? _green : _red),
          const SizedBox(width: 10),
          _metricChip('Avg Latency', c.influx.latencyMs != null ? '${c.influx.latencyMs}ms' : '—', color: _cyan),
        ]),
        const SizedBox(height: 12),
        if (c.healthLog.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _borderCol),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _t.primaryBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Row(children: [
                    _thCell('Time', 80),
                    _thCell('Level', 60),
                    Expanded(
                        child: Text('Message',
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _subText, letterSpacing: 0.7))),
                  ]),
                ),
                ...c.healthLog.take(8).map((l) {
                  final lColor = l.level == 'ok'
                      ? _green
                      : l.level == 'err'
                          ? _red
                          : l.level == 'warn'
                              ? _amber
                              : _cyan;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _borderCol.withOpacity(0.5))),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 80,
                        child: Text(l.time, style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
                      ),
                      SizedBox(
                        width: 60,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(l.level, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: lColor)),
                        ),
                      ),
                      Expanded(
                        child: Text(l.message, style: GoogleFonts.poppins(fontSize: 11, color: _t.primaryText.withOpacity(0.8))),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ] else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _t.primaryBackground,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _borderCol, style: BorderStyle.solid),
            ),
            child: Center(child: Text('No health check log yet.', style: GoogleFonts.poppins(fontSize: 12, color: _subText))),
          ),
        const SizedBox(height: 4),
        _ghostBtn(label: '↺ Refresh Log', onTap: () => _cubit.load(), t: _t, isLight: _isLight),
      ],
    );
  }

  Widget _thCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _subText, letterSpacing: 0.7)),
    );
  }

  Widget _metricChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _t.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderCol),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _subText, letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? _t.primaryText)),
      ]),
    );
  }

  // ── Change history section ─────────────────────────────────────────────────
  Widget _historySection(ClientConfig c) {
    if (c.history.isEmpty) {
      return Center(child: Text('No history yet.', style: GoogleFonts.poppins(fontSize: 12, color: _subText)));
    }
    return Column(
      children: c.history.take(10).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final h = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 120,
              child: Text(h.ts, style: GoogleFonts.poppins(fontSize: 10, color: _subText)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(h.who, style: GoogleFonts.poppins(fontSize: 10, color: _cyan, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.msg, style: GoogleFonts.poppins(fontSize: 12, color: _t.primaryText)),
                  if (h.diffOld != null && h.diffNew != null)
                    Row(children: [
                      Text('− ${h.diffOld}', style: GoogleFonts.poppins(fontSize: 10, color: _red)),
                      const SizedBox(width: 12),
                      Text('+ ${h.diffNew}', style: GoogleFonts.poppins(fontSize: 10, color: _green)),
                    ]),
                ],
              ),
            ),
            if (i == 0 && h.diffOld != null) _ghostBtn(label: '↺ Rollback', onTap: () {}, t: _t, isLight: _isLight),
          ]),
        );
      }).toList(),
    );
  }

  // ── Setup checklist section ────────────────────────────────────────────────
  Widget _checklistSection(ClientConfig c) {
    final ck = c.checklist;
    final steps = [
      (k: 'created', label: 'Client Record Created', sub: 'Domain, client code, plants, and contact configured', done: ck.created),
      (k: 'influx', label: 'InfluxDB Connected', sub: 'Host, organisation, buckets, and API token verified', done: ck.influx),
      (k: 'mysql', label: 'MySQL Connected', sub: 'Host, database name, username, and password verified', done: ck.mysql),
      (k: 'stag', label: 'Site Tag Mapping Done', sub: 'InfluxDB site tags linked to SF365 Plant records', done: ck.stag),
      (k: 'channel', label: 'Channel Mapping Done', sub: 'Device channels mapped to InfluxDB field keys', done: ck.channel),
      (k: 'perms', label: 'Module Permissions Set', sub: 'Client modules enabled in User & Access', done: ck.perms),
      (k: 'live', label: 'Client Portal Live', sub: 'All widgets routing data through Data Query Service', done: ck.live),
    ];

    bool prevDone = true;
    return Column(
      children: steps.map((s) {
        final isNext = !s.done && prevDone;
        final color = s.done ? _green : (isNext ? _cyan : _subText);
        prevDone = s.done;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.done
                    ? _green.withOpacity(0.12)
                    : isNext
                        ? _cyan.withOpacity(0.1)
                        : _t.primaryBackground,
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  s.done ? '✓' : (isNext ? '→' : '○'),
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  Text(s.sub, style: GoogleFonts.poppins(fontSize: 10, color: _subText)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: s.done
                    ? _green.withOpacity(0.1)
                    : isNext
                        ? _amber.withOpacity(0.1)
                        : _t.primaryBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.done
                      ? _green.withOpacity(0.25)
                      : isNext
                          ? _amber.withOpacity(0.25)
                          : _borderCol,
                ),
              ),
              child: Text(
                s.done ? 'Done' : (isNext ? 'Next Step' : 'Pending'),
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: s.done ? _green : (isNext ? _amber : _subText)),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ── Collapsible section ────────────────────────────────────────────────────
  Widget _collapsibleSection({
    required String id,
    required IconData icon,
    required String title,
    required String meta,
    required Widget child,
    Color? metaColor,
  }) {
    final open = _sectionOpen[id] ?? true;
    return CardWidget(
      topPadMultiplier: 1.0,
      bottomPadMultiplier: 1.0,
      builder: (ctx, sizing) => Column(children: [
        InkWell(
          onTap: () => setState(() => _sectionOpen[id] = !open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Icon(icon, size: 16, color: _subText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _t.primaryText)),
              ),
              Text(meta, style: GoogleFonts.poppins(fontSize: 11, color: metaColor ?? _subText)),
              const SizedBox(width: 8),
              Icon(
                open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _subText,
              ),
            ]),
          ),
        ),
        if (open) ...[
          Divider(height: 1, color: _borderCol),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ]),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer(ClientConfig c, _ClientFormState f) {
    return Row(children: [
      _dangerBtn(
        label: '🗑  Remove Client',
        onTap: () => _showRemoveDialog(c),
      ),
      const Spacer(),
      _ghostBtn(
        label: 'Discard',
        onTap: () {
          setState(() {
            _dirty = false;
            _forms[c.id] = _ClientFormState.from(c);
          });
        },
        t: _t,
        isLight: _isLight,
      ),
      const SizedBox(width: 8),
      _primaryBtn(
        label: '💾  Save & Deploy',
        onTap: () => _runDeploy(c, f),
        t: _t,
        isLight: _isLight,
      ),
    ]);
  }

  // ── Buttons ────────────────────────────────────────────────────────────────
  Widget _primaryBtn({
    required String label,
    required VoidCallback onTap,
    required FlutterFlowTheme t,
    required bool isLight,
  }) {
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
          child: Text(label,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isLight ? Colors.white : const Color(0xFF0A0E1A))),
        ),
      ),
    );
  }

  Widget _ghostBtn({
    required String label,
    required VoidCallback onTap,
    required FlutterFlowTheme t,
    required bool isLight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderCol),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _subText)),
        ),
      ),
    );
  }

  Widget _secondaryBtn({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _t.primaryBackground,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _borderCol),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _t.primaryText)),
        ),
      ),
    );
  }

  Widget _dangerBtn({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _red.withOpacity(0.25)),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _red)),
        ),
      ),
    );
  }

  Widget _smallBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  Future<void> _showAddDialog() async {
    final st = _cubit.state;
    final existingIds = st is IntegrationConfigLoaded ? st.clients.map((c) => c.id).toList() : <String>[];
    final result = await showDialog<ClientConfig>(
      context: context,
      builder: (_) => AddClientDialog(existingClientIds: existingIds),
    );
    if (result != null && mounted) {
      _cubit.addClient(result);
    }
  }

  // Edits Name/Plan only — Code/ID stays fixed since it's the Firestore doc
  // id and the value sent as x-client-id everywhere; renaming it would break
  // every already-working connection for that client.
  Future<void> _showEditClientDialog(ClientConfig c) async {
    final nameCtr = TextEditingController(text: c.name);
    String plan = c.plan;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final cardBg = _isLight ? Colors.white : const Color(0xFF1A1F2E);
          final fieldBg = _isLight ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

          return Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Edit Client',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _t.primaryText)),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Icon(Icons.close, size: 18, color: _subText),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Code "${c.code}" can\'t be changed — it\'s used as the live x-client-id.',
                        style: GoogleFonts.poppins(fontSize: 11, color: _subText)),
                    const SizedBox(height: 16),

                    Text('Client Name', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _t.primaryText)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameCtr,
                      style: GoogleFonts.poppins(fontSize: 13, color: _t.primaryText),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fieldBg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderCol), borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _t.primary), borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Subscription Plan', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _t.primaryText)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderCol)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: plan,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          style: GoogleFonts.poppins(fontSize: 13, color: _t.primaryText),
                          items: ['Trial', 'Basic', 'Enterprise']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(fontSize: 13, color: _t.primaryText))))
                              .toList(),
                          onChanged: (v) => setDialogState(() => plan = v ?? plan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      _ghostBtn(label: 'Cancel', onTap: () => Navigator.of(ctx).pop(false), t: _t, isLight: _isLight),
                      const SizedBox(width: 10),
                      _primaryBtn(label: 'Save Changes', onTap: () => Navigator.of(ctx).pop(true), t: _t, isLight: _isLight),
                    ]),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (saved == true && mounted) {
      final newName = nameCtr.text.trim();
      if (newName.isNotEmpty) {
        _cubit.save(c.copyWith(name: newName, plan: plan));
        _snack('Client updated', ok: true);
      }
    }
  }

  Future<void> _showRemoveDialog(ClientConfig c) async {
    final codeController = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final isLight = Theme.of(ctx).brightness == Brightness.light;
          final cardBg = isLight ? Colors.white : const Color(0xFF1A1F2E);
          final borderCol = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);

          return Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, color: _red, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Remove Client', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _t.primaryText)),
                      ),
                      InkWell(onTap: () => Navigator.of(ctx).pop(), child: const Icon(Icons.close, size: 18)),
                    ]),
                  ),
                  // Warning
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _red.withOpacity(0.2)),
                    ),
                    child: Text(
                      '⚠ This permanently disconnects all widgets for ${c.name} from the Data Query Service. This cannot be undone.',
                      style: GoogleFonts.poppins(fontSize: 12, color: _red, height: 1.5),
                    ),
                  ),
                  // Confirm field
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type client code "${c.code}" to confirm', style: GoogleFonts.poppins(fontSize: 12, color: _subText)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: codeController,
                          onChanged: (v) {
                            setDialogState(() {
                              confirmed = v.trim().toUpperCase() == c.code;
                            });
                          },
                          style: GoogleFonts.poppins(fontSize: 13, color: _t.primaryText),
                          decoration: InputDecoration(
                            hintText: 'Type client code…',
                            hintStyle: GoogleFonts.poppins(fontSize: 12, color: _subText),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: _t.primaryBackground,
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderCol), borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _red), borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol)),
                            child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12, color: _subText))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: confirmed
                              ? () {
                                  Navigator.of(ctx).pop();
                                  _cubit.removeClient(c.id);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: confirmed ? _red : _red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                                child: Text('Remove Client',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    codeController.dispose();
  }

  // ── Test all ───────────────────────────────────────────────────────────────
  void _testAll(List<ClientConfig> clients) {
    for (final c in clients) {
      _cubit.testConnection(c, 'influx');
      _cubit.testConnection(c, 'mysql');
    }
  }

  // ── Loading / error states ─────────────────────────────────────────────────
  Widget _loading() {
    return Scaffold(
      backgroundColor: _t.primaryBackground,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: _t.primary),
          const SizedBox(height: 16),
          Text('Loading integration config…', style: GoogleFonts.poppins(fontSize: 13, color: _subText)),
        ]),
      ),
    );
  }

  Widget _errorView(String msg) {
    return Scaffold(
      backgroundColor: _t.primaryBackground,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: _red, size: 40),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: _red)),
          const SizedBox(height: 16),
          _primaryBtn(label: 'Retry', onTap: () => _cubit.load(), t: _t, isLight: _isLight),
        ]),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withOpacity(0.25)),
          ),
          child: Icon(Icons.cable_rounded, color: _accent, size: 26),
        ),
        const SizedBox(height: 14),
        Text('No clients configured', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _t.primaryText)),
        const SizedBox(height: 6),
        Text('Add a client to configure InfluxDB & MySQL connections.', style: GoogleFonts.poppins(fontSize: 13, color: _subText)),
        const SizedBox(height: 18),
        _primaryBtn(label: '＋  Add First Client', onTap: _showAddDialog, t: _t, isLight: _isLight),
      ]),
    );
  }
}

// ── Per-client form state ──────────────────────────────────────────────────────
class _ClientFormState {
  // InfluxDB
  final TextEditingController influxHost;
  final TextEditingController influxOrg;
  final TextEditingController influxBucketRaw;
  final TextEditingController influxBucketPred;
  final TextEditingController influxBucketOee;
  final TextEditingController influxToken;
  bool influxTokenChanged;
  int influxRetryAttempts;
  int influxRetryInterval;
  String influxOnFailure;
  final TextEditingController influxMeasurement;
  final TextEditingController influxDeviceIdTag;
  final TextEditingController influxDeviceTypeTag;
  final TextEditingController influxDeviceTypeVal;

  // MySQL
  final TextEditingController mysqlHost;
  final TextEditingController mysqlPort;
  final TextEditingController mysqlDb;
  final TextEditingController mysqlUser;
  final TextEditingController mysqlPw;
  bool mysqlPwChanged;
  int mysqlRetryAttempts;
  int mysqlRetryInterval;
  String mysqlOnFailure;

  // Firebase
  final TextEditingController fbProjectId;
  final TextEditingController fbSecret;
  bool fbSecretChanged;

  // Site tag add form
  final TextEditingController newTagCtr;
  String newTagPlant;

  _ClientFormState({
    required this.influxHost,
    required this.influxOrg,
    required this.influxBucketRaw,
    required this.influxBucketPred,
    required this.influxBucketOee,
    required this.influxToken,
    required this.influxTokenChanged,
    required this.influxRetryAttempts,
    required this.influxRetryInterval,
    required this.influxOnFailure,
    required this.influxMeasurement,
    required this.influxDeviceIdTag,
    required this.influxDeviceTypeTag,
    required this.influxDeviceTypeVal,
    required this.mysqlHost,
    required this.mysqlPort,
    required this.mysqlDb,
    required this.mysqlUser,
    required this.mysqlPw,
    required this.mysqlPwChanged,
    required this.mysqlRetryAttempts,
    required this.mysqlRetryInterval,
    required this.mysqlOnFailure,
    required this.fbProjectId,
    required this.fbSecret,
    required this.fbSecretChanged,
    required this.newTagCtr,
    required this.newTagPlant,
  });

  factory _ClientFormState.from(ClientConfig c) => _ClientFormState(
        influxHost: TextEditingController(text: c.influx.host),
        influxOrg: TextEditingController(text: c.influx.org),
        influxBucketRaw: TextEditingController(text: c.influx.bucketRaw),
        influxBucketPred: TextEditingController(text: c.influx.bucketPredictions),
        influxBucketOee: TextEditingController(text: c.influx.bucketOee),
        influxToken: TextEditingController(text: c.influx.token),
        influxTokenChanged: false,
        influxRetryAttempts: c.influx.retryAttempts,
        influxRetryInterval: c.influx.retryInterval,
        influxOnFailure: c.influx.onFailure,
        influxMeasurement: TextEditingController(text: c.influx.measurement),
        influxDeviceIdTag: TextEditingController(text: c.influx.deviceIdTag),
        influxDeviceTypeTag: TextEditingController(text: c.influx.deviceTypeTag),
        influxDeviceTypeVal: TextEditingController(text: c.influx.deviceTypeVal),
        mysqlHost: TextEditingController(text: c.mysql.host),
        mysqlPort: TextEditingController(text: c.mysql.port),
        mysqlDb: TextEditingController(text: c.mysql.database),
        mysqlUser: TextEditingController(text: c.mysql.username),
        mysqlPw: TextEditingController(),
        mysqlPwChanged: false,
        mysqlRetryAttempts: c.mysql.retryAttempts,
        mysqlRetryInterval: c.mysql.retryInterval,
        mysqlOnFailure: c.mysql.onFailure,
        fbProjectId: TextEditingController(text: c.firebase.projectId),
        fbSecret: TextEditingController(),
        fbSecretChanged: false,
        newTagCtr: TextEditingController(),
        newTagPlant: c.plants.isNotEmpty ? c.plants.first : '',
      );

  void dispose() {
    influxHost.dispose();
    influxOrg.dispose();
    influxBucketRaw.dispose();
    influxBucketPred.dispose();
    influxBucketOee.dispose();
    influxToken.dispose();
    influxMeasurement.dispose();
    influxDeviceIdTag.dispose();
    influxDeviceTypeTag.dispose();
    influxDeviceTypeVal.dispose();
    mysqlHost.dispose();
    mysqlPort.dispose();
    mysqlDb.dispose();
    mysqlUser.dispose();
    mysqlPw.dispose();
    fbProjectId.dispose();
    fbSecret.dispose();
    newTagCtr.dispose();
  }
}

// ── Test result data ────────────────────────────────────────────────────────
class _ConnTestResult {
  final bool ok;
  final int? ms;
  _ConnTestResult({required this.ok, this.ms});
}

// ── Equal-height pair ────────────────────────────────────────────────────────
// Measures both children after first frame, constrains both to the max height.
// This gives CardWidget (LayoutBuilder) a bounded height so it works correctly.
class _EqualHeightPair extends StatefulWidget {
  final Widget left;
  final Widget right;
  const _EqualHeightPair({
    required this.left,
    required this.right,
  });

  @override
  State<_EqualHeightPair> createState() => _EqualHeightPairState();
}

class _EqualHeightPairState extends State<_EqualHeightPair> {
  final _leftKey = GlobalKey();
  final _rightKey = GlobalKey();
  double? _height;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(_EqualHeightPair old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(_) {
    final lBox = _leftKey.currentContext?.findRenderObject() as RenderBox?;
    final rBox = _rightKey.currentContext?.findRenderObject() as RenderBox?;
    if (lBox == null || rBox == null) return;
    final maxH = lBox.size.height > rBox.size.height ? lBox.size.height : rBox.size.height;
    if (maxH > 0 && maxH != _height) setState(() => _height = maxH);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ConstrainedBox(
            key: _leftKey,
            constraints: BoxConstraints(minHeight: _height ?? 0),
            child: widget.left,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ConstrainedBox(
            key: _rightKey,
            constraints: BoxConstraints(minHeight: _height ?? 0),
            child: widget.right,
          ),
        ),
      ],
    );
  }
}
