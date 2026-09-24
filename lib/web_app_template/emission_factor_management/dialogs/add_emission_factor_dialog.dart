import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../emission_factor_model.dart';

enum _SubmitMode { draft, activate }

class AddEmissionFactorDialog extends StatefulWidget {
  final int currentActiveFiscalYear;
  final List<int> existingFiscalYears;
  final EmissionFactor? initialFactor;
  final Future<bool> Function({
    required int fiscalYear,
    required double factor,
    required String source,
    double? carbonCost,
    required DateTime publishedDate,
    required DateTime effectiveFrom,
    required String documentReference,
    String? notes,
    required bool activate,
  }) onSubmit;

  final bool canActivate;

  const AddEmissionFactorDialog({
    super.key,
    required this.currentActiveFiscalYear,
    required this.existingFiscalYears,
    required this.onSubmit,
    this.initialFactor,
    this.canActivate = true,
  });

  @override
  State<AddEmissionFactorDialog> createState() =>
      _AddEmissionFactorDialogState();
}

class _AddEmissionFactorDialogState extends State<AddEmissionFactorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _factorCtrl = TextEditingController();
  final _carbonCostCtrl = TextEditingController();
  final _docRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late int _selectedFiscalYear;
  String _selectedSource = 'Tenaga Nasional Berhad (TNB)';
  DateTime _publishedDate = DateTime.now();
  late DateTime _effectiveFrom;
  bool _loading = false;
  _SubmitMode? _pendingMode;

  static const _sources = [
    'Tenaga Nasional Berhad (TNB)',
    'Suruhanjaya Tenaga (ST)',
    'MyHijau / MGTC',
    'GHG Protocol',
    'Other',
  ];

  static const _kMalaysiaGridMin = 0.40;
  static const _kMalaysiaGridMax = 0.80;

  bool get _isEditing => widget.initialFactor != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initialFactor;
    if (init != null) {
      _selectedFiscalYear = init.fiscalYear;
      _factorCtrl.text = init.factor?.toStringAsFixed(3) ?? '';
      _carbonCostCtrl.text = init.carbonCost?.toStringAsFixed(2) ?? '';
      _selectedSource = _sources.contains(init.source) ? init.source : _sources.first;
      _publishedDate = init.publishedDate ?? DateTime.now();
      _effectiveFrom = init.effectiveFrom;
      _docRefCtrl.text = init.documentReference ?? '';
      _notesCtrl.text = init.notes ?? '';
    } else {
      final nextYear = (widget.existingFiscalYears.isEmpty
              ? DateTime.now().year
              : widget.existingFiscalYears.reduce((a, b) => a > b ? a : b)) +
          1;
      _selectedFiscalYear = nextYear;
      _effectiveFrom = DateTime(_selectedFiscalYear, 1, 1);
    }
  }

  @override
  void dispose() {
    _factorCtrl.dispose();
    _carbonCostCtrl.dispose();
    _docRefCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double? get _parsedFactor => double.tryParse(_factorCtrl.text.trim());

  double? get _parsedCarbonCost => double.tryParse(_carbonCostCtrl.text.trim());

  bool get _factorOutOfRange {
    final v = _parsedFactor;
    if (v == null) return false;
    return v < _kMalaysiaGridMin || v > _kMalaysiaGridMax;
  }

  bool get _isActiveYear =>
      _selectedFiscalYear == widget.currentActiveFiscalYear;

  Future<void> _submit(_SubmitMode mode) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _pendingMode = mode;
    });

    final success = await widget.onSubmit(
      fiscalYear: _selectedFiscalYear,
      factor: _parsedFactor!,
      source: _selectedSource,
      carbonCost: _parsedCarbonCost,
      publishedDate: _publishedDate,
      effectiveFrom: _effectiveFrom,
      documentReference: _docRefCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      activate: mode == _SubmitMode.activate,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _pendingMode = null;
    });
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final barColor =
        isLight ? Colors.white : const Color(0xFF111827);
    final cardBg = isLight ? Colors.white : const Color(0xFF1E2432);
    final cardBorder =
        isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);
    final titleColor =
        isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final subColor =
        isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final labelColor =
        isLight ? const Color(0xFF374151) : const Color(0xFFCDD5E0);
    final inputBg =
        isLight ? const Color(0xFFF8FAFC) : const Color(0xFF131C30);
    final inputBorder =
        isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C3A55);
    final submitTextColor = isLight ? Colors.white : const Color(0xFF0A0E1A);

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)]
                : [const Color(0xFF0A0E1A), const Color(0xFF12193A)],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: barColor,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: t.primary.withOpacity(0.2), width: 1),
                    ),
                    child: Center(
                      child: Icon(Icons.add_chart_outlined,
                          size: 18, color: t.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Emission Factor' : 'Add New Emission Factor',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'Update the FY${widget.initialFactor!.fiscalYear} emission factor entry.'
                              : 'Create a new TNB grid emission factor entry. Save as Draft until ST Malaysia officially publishes the value.',
                          style:
                              TextStyle(color: subColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF384A78).withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Icon(Icons.close,
                          size: 16, color: subColor),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Warning banner if active year
                          if (_isActiveYear)
                            _activationWarningBanner(t, isLight),
                          if (_isActiveYear) const SizedBox(height: 20),

                          // Form card
                          _formCard(
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            labelColor: labelColor,
                            inputBg: inputBg,
                            inputBorder: inputBorder,
                            subColor: subColor,
                            t: t,
                            isLight: isLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: barColor,
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: subColor.withOpacity(0.6)),
                  const SizedBox(width: 7),
                  Text(
                    'Fields marked with * are required',
                    style: TextStyle(
                        color: subColor.withOpacity(0.6), fontSize: 12),
                  ),
                  const Spacer(),
                  // Cancel
                  InkWell(
                    onTap: _loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E2A48),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Save as Draft
                  InkWell(
                    onTap: (_loading ||
                            (_loading &&
                                _pendingMode == _SubmitMode.draft))
                        ? null
                        : () => _submit(_SubmitMode.draft),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E2A48),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: _loading &&
                                  _pendingMode == _SubmitMode.draft
                              ? t.primary.withOpacity(0.4)
                              : cardBorder,
                          width: 1,
                        ),
                      ),
                      child: _loading &&
                              _pendingMode == _SubmitMode.draft
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: t.primary),
                            )
                          : Text(
                              'Save as Draft',
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF374151)
                                    : t.primaryText.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ),
                  if (widget.canActivate) ...[
                  const SizedBox(width: 10),
                  // Activate
                  InkWell(
                    onTap: (_loading &&
                            _pendingMode == _SubmitMode.activate)
                        ? null
                        : () => _submit(_SubmitMode.activate),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 10),
                      decoration: BoxDecoration(
                        color: _loading ? t.primary.withOpacity(0.5) : t.primary,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _loading
                            ? []
                            : [
                                BoxShadow(
                                  color: t.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: _loading &&
                              _pendingMode == _SubmitMode.activate
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: submitTextColor),
                            )
                          : Text(
                              'Activate',
                              style: TextStyle(
                                color: submitTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ),
                  ],  // end if (widget.canActivate)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activationWarningBanner(dynamic t, bool isLight) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: t.warning),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, height: 1.5, color: t.warning),
                children: [
                  const TextSpan(text: 'If you Activate a factor for '),
                  TextSpan(
                    text: 'FY${widget.currentActiveFiscalYear} (current active year)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text:
                        ', all linked Scope 2 CO₂e figures will be recalculated and tagged ',
                  ),
                  const TextSpan(
                    text: 'Restated',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                      text: '. This is logged permanently.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({
    required Color cardBg,
    required Color cardBorder,
    required Color labelColor,
    required Color inputBg,
    required Color inputBorder,
    required Color subColor,
    required dynamic t,
    required bool isLight,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.06 : 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Fiscal Year + Factor
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _fiscalYearDropdown(
                    labelColor, inputBg, inputBorder, subColor, t, isLight),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _factorInput(
                    labelColor, inputBg, inputBorder, subColor, t, isLight),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _carbonCostInput(
                    labelColor, inputBg, inputBorder, subColor, t, isLight),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Source authority
          _sourceDropdown(
              labelColor, inputBg, inputBorder, subColor, t, isLight),
          const SizedBox(height: 18),
          // Row 2: Published date + Effective from
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _publishedDateField(
                    labelColor, inputBg, inputBorder, subColor, t, isLight),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _effectiveFromField(
                    labelColor, inputBg, inputBorder, subColor, t, isLight),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Document reference
          _textField(
            label: 'DOCUMENT REFERENCE *',
            hint: 'e.g. ST Grid Emission Factor Report 2026, Table 3',
            helper: 'Required for Bursa audit trail',
            controller: _docRefCtrl,
            labelColor: labelColor,
            inputBg: inputBg,
            inputBorder: inputBorder,
            subColor: subColor,
            t: t,
            isLight: isLight,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 18),
          // Notes
          _textField(
            label: 'NOTES (OPTIONAL)',
            hint: 'e.g. Slight decrease due to higher renewable mix',
            controller: _notesCtrl,
            labelColor: labelColor,
            inputBg: inputBg,
            inputBorder: inputBorder,
            subColor: subColor,
            t: t,
            isLight: isLight,
          ),
        ],
      ),
    );
  }

  Widget _fiscalYearDropdown(Color labelColor, Color inputBg, Color inputBorder,
      Color subColor, dynamic t, bool isLight) {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('FISCAL YEAR', labelColor),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _inputDecoration(inputBg, inputBorder, t),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FY $_selectedFiscalYear',
                style: TextStyle(
                  fontSize: 14,
                  color: isLight ? const Color(0xFF1E293B) : t.primaryText,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Build the list: existing years + next two upcoming years
    final years = <int>{};
    years.addAll(widget.existingFiscalYears);
    final now = DateTime.now().year;
    years.add(now + 1);
    years.add(now + 2);
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));

    if (!sortedYears.contains(_selectedFiscalYear)) {
      sortedYears.insert(0, _selectedFiscalYear);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('FISCAL YEAR', labelColor),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _inputDecoration(inputBg, inputBorder, t),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedFiscalYear,
              dropdownColor: isLight ? Colors.white : const Color(0xFF1E2432),
              isExpanded: true,
              style: TextStyle(
                  fontSize: 14,
                  color: isLight
                      ? const Color(0xFF1E293B)
                      : t.primaryText),
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 18, color: subColor),
              items: sortedYears
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('FY $y'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedFiscalYear = v;
                    _effectiveFrom = DateTime(v, 1, 1);
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _factorInput(Color labelColor, Color inputBg, Color inputBorder,
      Color subColor, dynamic t, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('FACTOR (kgCO₂e/kWH) *', labelColor),
        const SizedBox(height: 6),
        TextFormField(
          controller: _factorCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: TextStyle(
            fontSize: 14,
            color: isLight ? const Color(0xFF1E293B) : t.primaryText,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. 0.562',
            hintStyle: TextStyle(color: subColor.withOpacity(0.5), fontSize: 14),
            filled: true,
            fillColor: inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: t.primary.withOpacity(0.5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.error.withOpacity(0.6), width: 1),
            ),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (double.tryParse(v.trim()) == null) return 'Invalid number';
            return null;
          },
        ),
        if (_factorOutOfRange) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 12, color: t.warning),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Value outside typical Malaysia grid range (0.40–0.80). Please verify source document.',
                  style: TextStyle(
                      fontSize: 11, color: t.warning),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _carbonCostInput(Color labelColor, Color inputBg, Color inputBorder,
      Color subColor, dynamic t, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('CARBON COST (RM / tCO₂e)', labelColor),
        const SizedBox(height: 6),
        TextFormField(
          controller: _carbonCostCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: TextStyle(
            fontSize: 14,
            color: isLight ? const Color(0xFF1E293B) : t.primaryText,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. 79.00',
            hintStyle: TextStyle(color: subColor.withOpacity(0.5), fontSize: 14),
            filled: true,
            fillColor: inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: t.primary.withOpacity(0.5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.error.withOpacity(0.6), width: 1),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (double.tryParse(v.trim()) == null) return 'Invalid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _sourceDropdown(Color labelColor, Color inputBg, Color inputBorder,
      Color subColor, dynamic t, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('SOURCE AUTHORITY', labelColor),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _inputDecoration(inputBg, inputBorder, t),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSource,
              dropdownColor:
                  isLight ? Colors.white : const Color(0xFF1E2432),
              isExpanded: true,
              style: TextStyle(
                  fontSize: 14,
                  color: isLight
                      ? const Color(0xFF1E293B)
                      : t.primaryText),
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 18, color: subColor),
              items: _sources
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedSource = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _publishedDateField(Color labelColor, Color inputBg, Color inputBorder,
      Color subColor, dynamic t, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('ST PUBLICATION DATE', labelColor),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _publishedDate,
              firstDate: DateTime(2010),
              lastDate: DateTime(2035),
              helpText: 'Select publication date',
            );
            if (picked != null) setState(() => _publishedDate = picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _inputDecoration(inputBg, inputBorder, t),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_monthName(_publishedDate.month)}  ${_publishedDate.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isLight
                          ? const Color(0xFF1E293B)
                          : t.primaryText,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 15, color: subColor.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _effectiveFromField(Color labelColor, Color inputBg,
      Color inputBorder, Color subColor, dynamic t, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('EFFECTIVE FROM', labelColor),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _effectiveFrom,
              firstDate: DateTime(2010),
              lastDate: DateTime(2035),
            );
            if (picked != null) setState(() => _effectiveFrom = picked);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _inputDecoration(inputBg, inputBorder, t),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_effectiveFrom.day.toString().padLeft(2, '0')} / ${_effectiveFrom.month.toString().padLeft(2, '0')} / ${_effectiveFrom.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isLight
                          ? const Color(0xFF1E293B)
                          : t.primaryText,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 15, color: subColor.withOpacity(0.6)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Usually 1 Jan of fiscal year',
          style: TextStyle(fontSize: 11, color: subColor.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    String? helper,
    required TextEditingController controller,
    required Color labelColor,
    required Color inputBg,
    required Color inputBorder,
    required Color subColor,
    required dynamic t,
    required bool isLight,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, labelColor),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 14,
            color: isLight ? const Color(0xFF1E293B) : t.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: subColor.withOpacity(0.45), fontSize: 14),
            helperText: helper,
            helperStyle:
                TextStyle(color: subColor.withOpacity(0.5), fontSize: 11),
            filled: true,
            fillColor: inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: t.primary.withOpacity(0.5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: t.error.withOpacity(0.6), width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: color,
        ),
      );

  BoxDecoration _inputDecoration(
      Color inputBg, Color inputBorder, dynamic t) {
    return BoxDecoration(
      color: inputBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: inputBorder, width: 1),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
