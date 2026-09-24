import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/rbac.dart';
import '../../utils/report_exporter_saver_io.dart' if (dart.library.html) '../../utils/report_exporter_saver_web.dart' as saver;
import 'emission_factor_model.dart';
import 'cubit/emission_factor_cubit.dart';
import 'cubit/emission_factor_state.dart';
import 'widgets/summary_metric_card.dart';
import 'widgets/calculation_formula_panel.dart';
import 'widgets/factor_version_table.dart';
import 'dialogs/audit_log_dialog.dart';
import 'dialogs/add_emission_factor_dialog.dart';
import 'dialogs/activate_confirm_dialog.dart';

class EmissionFactorManagementWidget extends StatefulWidget {
  const EmissionFactorManagementWidget({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<EmissionFactorManagementWidget> createState() => _EmissionFactorManagementWidgetState();
}

class _EmissionFactorManagementWidgetState extends State<EmissionFactorManagementWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final EmissionFactorCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = EmissionFactorCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ── Helper getters from loaded state ──────────────────────────────────────

  String get _actorEmail => AppStateNotifier.instance.userEmail ?? 'admin@novaflow';

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showAuditLog(List<AuditLogEntry> auditLog) {
    showDialog(
      context: context,
      builder: (_) => AuditLogDialog(
        entries: auditLog,
        onExportCsv: () => _exportAuditLogCsv(auditLog),
      ),
    );
  }

  void _exportAuditLogCsv(List<AuditLogEntry> auditLog) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Action,Fiscal Year,From Value,To Value,Actor');
    for (final entry in auditLog) {
      final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp);
      final from = entry.fromValue?.toStringAsFixed(3) ?? '';
      final to = entry.toValue?.toStringAsFixed(3) ?? '';
      final actor = entry.actor.contains(',') ? '"${entry.actor}"' : entry.actor;
      buffer.writeln('$ts,${entry.actionLabel},${entry.fiscalYear},$from,$to,$actor');
    }
    final bytes = utf8.encode(buffer.toString());
    final fileName = 'emission_factor_audit_log_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    saver.saveExcelBytes(bytes: bytes, fileName: fileName);
  }

  void _showAddFactorDialog({
    required List<EmissionFactor> factors,
    bool canActivate = true,
    EmissionFactor? initialFactor,
  }) {
    final existingYears = factors.map((f) => f.fiscalYear).toList();
    final activeYear = factors.where((f) => f.status == FactorStatus.active).firstOrNull;
    showDialog(
      context: context,
      builder: (_) => AddEmissionFactorDialog(
        currentActiveFiscalYear: activeYear?.fiscalYear ?? DateTime.now().year,
        existingFiscalYears: existingYears,
        canActivate: canActivate,
        initialFactor: initialFactor,
        onSubmit: ({
          required int fiscalYear,
          required double factor,
          required String source,
          double? carbonCost,
          required DateTime publishedDate,
          required DateTime effectiveFrom,
          required String documentReference,
          String? notes,
          required bool activate,
        }) async {
          return _cubit.saveEmissionFactor(
            fiscalYear: fiscalYear,
            factor: factor,
            source: source,
            carbonCost: carbonCost,
            publishedDate: publishedDate,
            effectiveFrom: effectiveFrom,
            documentReference: documentReference,
            notes: notes,
            activate: activate,
            actorEmail: _actorEmail,
          );
        },
      ),
    );
  }

  void _onActivateFactor(EmissionFactor factor) {
    if (factor.status != FactorStatus.draft) return;
    showDialog(
      context: context,
      builder: (_) => ActivateConfirmDialog(
        factor: factor,
        onConfirm: () => _cubit.activateFactor(factor, _actorEmail),
      ),
    );
  }

  void _onEditFactor(EmissionFactor factor, List<EmissionFactor> factors) {
    final role = AppStateNotifier.instance.userRole ?? '';
    const m = AppRoles.kModuleEmissionFactorMgmt;
    final canEdit = (factor.status == FactorStatus.draft && AppRoles.canAction(role, m, AppRoles.kEmfEditDraft)) ||
        (factor.status == FactorStatus.active && AppRoles.canAction(role, m, AppRoles.kEmfEditActive)) ||
        (factor.status == FactorStatus.locked && AppRoles.canAction(role, m, AppRoles.kEmfEditLocked));
    if (!canEdit) return;
    _showAddFactorDialog(
      factors: factors,
      canActivate: AppRoles.canAction(role, m, AppRoles.kEmfActivate),
      initialFactor: factor,
    );
  }

  void _onDeleteFactor(EmissionFactor factor) {
    final role = AppStateNotifier.instance.userRole ?? '';
    const m = AppRoles.kModuleEmissionFactorMgmt;
    final canDelete = (factor.status == FactorStatus.draft && AppRoles.canAction(role, m, AppRoles.kEmfDeleteDraft)) ||
        (factor.status == FactorStatus.active && AppRoles.canAction(role, m, AppRoles.kEmfDeleteActive)) ||
        (factor.status == FactorStatus.locked && AppRoles.canAction(role, m, AppRoles.kEmfDeleteLocked));
    if (!canDelete) return;
    showDialog(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        fiscalYear: factor.fiscalYear,
        onConfirm: () => _cubit.deleteFactor(factor, _actorEmail),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<EmissionFactorCubit, EmissionFactorState>(
        builder: (context, state) {
          if (state is EmissionFactorLoading || state is EmissionFactorInitial) {
            return _buildLoading();
          }
          if (state is EmissionFactorError) {
            return _buildError(state.message);
          }
          if (state is EmissionFactorLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading() {
    final t = FlutterFlowTheme.of(context);
    return Container(
      color: t.primaryBackground,
      child: Center(
        child: CircularProgressIndicator(color: t.primary),
      ),
    );
  }

  Widget _buildError(String message) {
    final t = FlutterFlowTheme.of(context);
    return Center(
      child: Text(
        'Failed to load emission factors: $message',
        style: TextStyle(color: t.error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmissionFactorLoaded state) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final userRole = AppStateNotifier.instance.userRole ?? '';
    const m = AppRoles.kModuleEmissionFactorMgmt;
    final canWrite = AppRoles.canAction(userRole, m, AppRoles.kEmfAddFactor);
    final canActivate = AppRoles.canAction(userRole, m, AppRoles.kEmfActivate);
    final canAuditLog = AppRoles.canAction(userRole, m, AppRoles.kEmfViewAuditLog);
    final isSuperAdmin = AppRoles.normalizeRole(userRole) == AppRoles.superAdmin;

    final factors = state.factors;
    final auditLog = state.auditLog;

    final activeFactor = factors.where((f) => f.status == FactorStatus.active).firstOrNull;
    final lockedFactors = factors.where((f) => f.status == FactorStatus.locked).toList()..sort((a, b) => b.fiscalYear.compareTo(a.fiscalYear));
    final previousFactor = lockedFactors.isEmpty ? null : lockedFactors.first;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded)
          _pageHeader(
            t,
            isLight,
            canWrite: canWrite,
            canActivate: canActivate,
            canAuditLog: canAuditLog,
            isSuperAdmin: isSuperAdmin,
            factors: factors,
            auditLog: auditLog,
          ),
        if (!widget.embedded) const SizedBox(height: 20),
        if (activeFactor != null) _infoBanner(t, isLight, activeFactor),
        if (activeFactor != null) const SizedBox(height: 20),
        _summaryCards(t, isLight, activeFactor, previousFactor, factors, auditLog),
        const SizedBox(height: 20),
        CalculationFormulaPanel(
          activeGridFactor: activeFactor?.factor ?? 0.574,
        ),
        const SizedBox(height: 24),
        FactorVersionTable(
          factors: factors,
          onRefresh: _cubit.refresh,
          onView: (_) {},
          onActivate: _onActivateFactor,
          onEdit: (f) => _onEditFactor(f, factors),
          onDelete: _onDeleteFactor,
        ),
        if (state.isSaving) ...[
          const SizedBox(height: 16),
          Center(child: CircularProgressIndicator(color: t.primary)),
        ],
      ],
    );

    if (widget.embedded) return content;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: t.primaryBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader(
                t,
                isLight,
                canWrite: canWrite,
                canActivate: canActivate,
                canAuditLog: canAuditLog,
                isSuperAdmin: isSuperAdmin,
                factors: factors,
                auditLog: auditLog,
              ),
              const SizedBox(height: 20),
              if (activeFactor != null) _infoBanner(t, isLight, activeFactor),
              if (activeFactor != null) const SizedBox(height: 20),
              _summaryCards(t, isLight, activeFactor, previousFactor, factors, auditLog),
              const SizedBox(height: 20),
              CalculationFormulaPanel(
                activeGridFactor: activeFactor?.factor ?? 0.574,
              ),
              const SizedBox(height: 24),
              FactorVersionTable(
                factors: factors,
                userRole: userRole,
                onRefresh: _cubit.refresh,
                onView: (_) {},
                onActivate: _onActivateFactor,
                onEdit: (f) => _onEditFactor(f, factors),
                onDelete: _onDeleteFactor,
              ),
              if (state.isSaving) ...[
                const SizedBox(height: 16),
                Center(child: CircularProgressIndicator(color: t.primary)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllConfirmDialog() {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1A2236),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: t.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: t.error.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Icon(Icons.delete_sweep_outlined, size: 18, color: t.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reset All Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'This will permanently delete all emission factors and audit log entries from Firestore. This action cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E2A48),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _cubit.clearAllData();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: t.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Reset All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageHeader(
    dynamic t,
    bool isLight, {
    bool canWrite = true,
    bool canActivate = true,
    bool canAuditLog = true,
    bool isSuperAdmin = false,
    required List<EmissionFactor> factors,
    required List<AuditLogEntry> auditLog,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Carbon Emission',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLight ? const Color(0xFF94A3B8) : t.secondaryText.withOpacity(0.4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.chevron_right,
                      size: 12,
                      color: isLight ? const Color(0xFFCBD5E1) : t.secondaryText.withOpacity(0.2),
                    ),
                  ),
                  Text(
                    'Emission Factor Management',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isLight ? const Color(0xFF64748B) : t.secondaryText.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Emission Factor Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                  color: isLight ? const Color(0xFF0F172A) : t.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage TNB grid emission factors for Scope 2 CO₂e — Kedah Facility · Method: GHG Protocol',
                style: TextStyle(
                  fontSize: 12,
                  color: isLight ? const Color(0xFF64748B) : t.secondaryText.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 10,
          children: [
            if (isSuperAdmin)
              // _ghostButton(
              //   label: 'Reset Data',
              //   icon: Icons.delete_sweep_outlined,
              //   onTap: _showClearAllConfirmDialog,
              //   t: t,
              //   isLight: isLight,
              //   destructive: true,
              // ),
              if (canAuditLog)
                _ghostButton(
                  label: 'Audit Log',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _showAuditLog(auditLog),
                  t: t,
                  isLight: isLight,
                ),
            if (canWrite)
              _primaryButton(
                label: '+ Add New Factor',
                onTap: () => _showAddFactorDialog(
                  factors: factors,
                  canActivate: canActivate,
                ),
                t: t,
                isLight: isLight,
              ),
          ],
        ),
      ],
    );
  }

  Widget _infoBanner(dynamic t, bool isLight, EmissionFactor active) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFEFF6FF) : t.info.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight ? const Color(0xFFBFDBFE) : t.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15, color: isLight ? const Color(0xFF3B82F6) : t.info),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: isLight ? const Color(0xFF1E40AF) : t.info.withOpacity(0.9),
                ),
                children: [
                  TextSpan(
                    text: 'FY${active.fiscalYear} Active Factor: ${active.factorDisplay} kgCO₂e/kWh',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' — Source: Suruhanjaya Tenaga (ST) Malaysia, Jan ${active.publishedDate?.year ?? active.fiscalYear}. '),
                  const TextSpan(text: 'Editing the active factor triggers cascade recalculation of all FY'),
                  TextSpan(text: '${active.fiscalYear}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' Scope 2 CO₂e and marks records as '),
                  const TextSpan(
                    text: 'Restated',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const TextSpan(text: '. All changes are logged.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(
    dynamic t,
    bool isLight,
    EmissionFactor? activeFactor,
    EmissionFactor? previousFactor,
    List<EmissionFactor> factors,
    List<AuditLogEntry> auditLog,
  ) {
    final a = activeFactor?.factor;
    final p = previousFactor?.factor;
    final yoy = (a != null && p != null && p != 0) ? ((a - p) / p) * 100 : 0.0;
    final isNeg = yoy <= 0;

    final factorsOnRecord = factors.where((f) => f.status != FactorStatus.draft).length;
    final nonDraft = factors.where((f) => f.status != FactorStatus.draft).map((f) => f.fiscalYear);
    final minYear = nonDraft.isEmpty ? 9999 : nonDraft.reduce((a, b) => a < b ? a : b);
    final maxYear = factors.where((f) => f.status == FactorStatus.locked).map((f) => f.fiscalYear).fold<int>(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 800;
      final cards = <Widget>[
        SummaryMetricCard(
          label: 'ACTIVE FACTOR (FY${activeFactor?.fiscalYear ?? '—'})',
          accentColor: t.primary,
          valueWidget: Text(
            activeFactor?.factorDisplay ?? '—',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: t.primary,
              letterSpacing: -0.5,
            ),
          ),
          subtitle: 'kgCO₂e / kWh · ST Malaysia',
        ),
        SummaryMetricCard(
          label: 'YoY FACTOR CHANGE',
          accentColor: isNeg ? t.success : t.error,
          valueWidget: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${isNeg ? '' : '+'}${yoy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isNeg ? t.success : t.error,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          subtitle: previousFactor != null ? 'vs FY${previousFactor.fiscalYear} (${previousFactor.factorDisplay} kgCO₂e/kWh)' : 'No prior year data',
        ),
        SummaryMetricCard(
          label: 'FACTORS ON RECORD',
          accentColor: t.secondary,
          valueWidget: Text(
            '$factorsOnRecord',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isLight ? const Color(0xFF1E293B) : t.primaryText,
              letterSpacing: -0.5,
            ),
          ),
          subtitle: minYear < 9999 && maxYear > 0 ? 'FY$minYear – FY$maxYear' : '—',
        ),
        SummaryMetricCard(
          label: 'LAST UPDATED',
          accentColor: t.tertiary,
          valueWidget: Text(
            auditLog.isNotEmpty ? _formatAuditDate(auditLog.first.timestamp) : '—',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isLight ? const Color(0xFF1E293B) : t.primaryText,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: auditLog.isNotEmpty ? 'by ${auditLog.first.actor}' : '—',
        ),
      ];

      if (isNarrow) {
        return Column(children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ]),
        ]);
      }

      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    });
  }

  String _formatAuditDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _ghostButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required dynamic t,
    required bool isLight,
    bool destructive = false,
  }) {
    final color = destructive ? t.error : (isLight ? const Color(0xFF64748B) : t.secondaryText);
    final borderColor = destructive ? t.error.withOpacity(0.35) : (isLight ? const Color(0xFFCBD5E1) : t.primary.withOpacity(0.2));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: destructive ? t.error.withOpacity(0.06) : null,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    required dynamic t,
    required bool isLight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: t.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: t.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLight ? Colors.white : const Color(0xFF0A0E1A),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delete confirmation dialog ─────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final int fiscalYear;
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({
    required this.fiscalYear,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A2236),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: t.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: t.error.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                    child: Icon(Icons.delete_outline, size: 18, color: t.error),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete Draft Factor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Are you sure you want to delete the FY $fiscalYear draft emission factor? This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E2A48),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder, width: 1),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: t.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
