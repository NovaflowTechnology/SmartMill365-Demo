part of 'plant_energy_command_center_setting_widget.dart';

// ── All build methods ──────────────────────────────────────────────────────────

extension _PeccBuild on _PlantEnergyCommandCenterSettingWidgetState {

  // ── Page root ──────────────────────────────────────────────────────────────

  Widget _buildPage(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final pageTitle = _settingsPageTitle;
    final body = Column(
      children: [
        if (!widget.embedded) ...[
          PageHeader(
            title: pageTitle,
            subtitle: 'Configure widgets, data sources and branding for the live dashboard',
            breadcrumbs: [
              const BreadcrumbItem(label: 'Settings', icon: Icons.settings_outlined),
              const BreadcrumbItem(label: 'Kanban Dashboard', icon: Icons.dashboard_outlined),
              BreadcrumbItem(label: pageTitle, icon: Icons.bolt_outlined),
            ],
            trailing: Row(children: _buildHeaderActions(context)),
          ),
          _buildSelectorBar(context),
        ] else
          _buildEmbeddedToolbar(context),
        if (_isSaving || _saveMessage != null) _buildWarningBanner(context),
        Expanded(
          child: (_isLoadingConfig || _isLoadingDevices)
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    widget.embedded ? 16 : 24,
                    0,
                    widget.embedded ? 16 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildProgressCard(context),
                      const SizedBox(height: 20),
                      if (!_isPerFactoryScope) ...[
                        _buildPinSection(context),
                        const SizedBox(height: 4),
                      ],
                      if (_usesMeterGroupLayout) ...[
                        _buildFoFiltersSection(context),
                        const SizedBox(height: 16),
                      ],
                      ..._sections
                          .where((sec) => !_isReplacedByPanel(sec.title))
                          .map((sec) => _buildSection(context, sec)),
                      if (!_isPerFactoryScope)
                        for (final spec in _panels) ...[
                          _buildPanelSection(context, spec),
                          const SizedBox(height: 4),
                        ],
                      const SizedBox(height: 12),
                      _buildBrandingSection(context),
                      const SizedBox(height: 24),
                      _buildFooter(context),
                    ],
                  ),
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: theme.primaryBackground,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(child: body),
    );
  }

  String get _settingsPageTitle {
    // Named after whichever block is open, since the same page now serves
    // Block A, B and C.
    if (_isLot237BlockScope) return '$_eccIdentity Energy Command Center';
    if (_isLot48Scope) return 'Lot 48 Energy Command Center';
    if (_isFlexiPlantScope) return '$_eccIdentity Energy Command Center';
    return 'Group Energy Command Center';
  }

  Widget _buildEmbeddedToolbar(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: kCyber.withOpacity(0.25))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Configure device groups, card filters and widget mappings for ${_eccIdentity.isNotEmpty ? _eccIdentity : 'this command center'}.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText),
            ),
          ),
          _OutlinedBtn(
            label: 'Refresh',
            icon: Icons.refresh,
            onTap: () {
              _fetchDevices();
              _loadConfig();
            },
          ),
          const SizedBox(width: 8),
          _OutlinedBtn(
            label: 'Overview',
            icon: Icons.dashboard_outlined,
            onTap: () => widget.onApplyOverview?.call(),
          ),
          const SizedBox(width: 8),
          _PrimaryBtn(
            label: _isSaving ? _savingStatus : 'Save & View Overview',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onTap: _save,
          ),
        ],
      ),
    );
  }

  // ── Header actions ─────────────────────────────────────────────────────────

  List<Widget> _buildHeaderActions(BuildContext context) {
    return [
      if (_usesMeterGroupLayout) ...[
        _OutlinedBtn(
          label: 'Back to Lot 237',
          icon: Icons.arrow_back,
          onTap: () {
            context.goNamed('PlantEnergyCommandCenterSetting', queryParameters: const {'plant': 'Lot 237'});
          },
        ),
        const SizedBox(width: 8),
      ],
      _OutlinedBtn(
        label: 'Refresh',
        icon: Icons.refresh,
        onTap: () { _fetchDevices(); _loadConfig(); },
      ),
      const SizedBox(width: 8),
      _PrimaryBtn(
        label: _isSaving ? _savingStatus : 'Save Configuration',
        icon: Icons.save_outlined,
        isLoading: _isSaving,
        onTap: _save,
      ),
    ];
  }

  // ── Selector bar ───────────────────────────────────────────────────────────

  /// Whether this plant is reached through its own settings page rather than
  /// through the production filter.
  ///
  /// Lot 237 is the whole site, and the blocks under it are what the production
  /// filter is for. It keeps its own command centre — the "Back to Lot 237"
  /// button opens it — so offering it here as though it were another
  /// production lot only invited someone to edit the site config by accident.
  bool _hasOwnSettingsPage(String plantName) =>
      plantName.trim().toLowerCase() == 'lot 237';

  /// Whether a plant belongs in the production filter.
  ///
  /// The master carries a few rows left over from testing — an unnamed one, a
  /// "testetes" — and a filter that offers them invites someone to configure a
  /// command centre for a plant that is not a plant. Matched on the name, so a
  /// row cleaned up in General Setting drops out of here on its own.
  bool _isProductionPlant(String plantName) {
    final n = plantName.trim().toLowerCase();
    if (n.isEmpty) return false;
    if (n.startsWith('test') || n.contains('testete')) return false;
    // A name with no digits is not one of the production lots; every real one
    // carries its number (Lot 48, Lot 237 Block B, …).
    if (!RegExp(r'\d').hasMatch(n)) return false;
    return true;
  }

  Widget _buildSelectorBar(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    Widget filterDropdown<T>({
      required String label,
      required T value,
      required List<DropdownMenuItem<T>> items,
      required void Function(T?) onChanged,
      bool isLoading = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.poppins(
                  fontSize: 12, letterSpacing: 0.6, color: kCyber, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          SizedBox(
            width: 210,
            child: Container(
              height: 40,
              decoration: cyberField(theme),
              alignment: Alignment.centerLeft,
              child: Row(children: [
                Container(width: 3, height: 40, color: kCyber.withOpacity(0.8)),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 15, height: 15,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: kCyber),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<T>(
                            value: value,
                            isExpanded: true,
                            isDense: true,
                            padding: const EdgeInsets.only(left: 12, right: 10),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kCyber),
                            dropdownColor: theme.secondaryBackground,
                            style: GoogleFonts.poppins(fontSize: 13, color: theme.primaryText),
                            items: items,
                            onChanged: onChanged,
                          ),
                        ),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(bottom: BorderSide(color: kCyber.withOpacity(0.25))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          filterDropdown<String>(
            label: 'Template',
            value: _selectedTemplate,
            items: _PlantEnergyCommandCenterSettingWidgetState._templateOptions
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t,
                          style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText)),
                    ))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedTemplate = v); },
          ),
          const SizedBox(width: 16),
          // A block centre is chosen by its production area, so the plant filter
          // has no job there and only invited someone to point this page at
          // another lot by accident. Lot 237 itself, and every other real
          // plant, still pick their centre from this Plant dropdown.
          if (_isLot237BlockScope)
            const SizedBox.shrink()
          else
          () {
            // The production lots this filter offers. Lot 237 is the whole site
            // and is set up from its own page, so it is never listed here — not
            // even while it is the current selection, which is what kept
            // putting it back at the bottom of the list.
            final offered = _plants
                .where((p) =>
                    _isProductionPlant(p['name']?.toString() ?? '') &&
                    !_hasOwnSettingsPage(p['name']?.toString() ?? ''))
                .toList();
            // A DropdownButton asserts its value matches exactly one item, so a
            // selection that is not offered falls back to "All plants" instead
            // of being passed through and crashing the page.
            final shown =
                offered.any((p) => p['id'] == _selectedPlantId) ? _selectedPlantId : '';
            return filterDropdown<String>(
              label: 'Plant',
              value: shown,
              isLoading: _isLoadingPlants,
              items: [
                DropdownMenuItem(
                    value: '',
                    child: Text('All plants',
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText))),
                ...offered.map((p) => DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['name'] as String,
                          style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText),
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) { if (v != null) _onPlantChanged(v); },
            );
          }(),
          const SizedBox(width: 16),
          filterDropdown<String>(
            label: 'Production Area',
            value: _selectedProductionArea,
            isLoading: _isLoadingProductionAreas || _isLoadingDevices,
            items: [
              DropdownMenuItem(
                  value: '',
                  child: Text('All production areas',
                      style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText))),
              ..._productionAreaOptions.map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(a,
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText),
                        overflow: TextOverflow.ellipsis),
                  )),
              // Keep a stale saved selection addressable so the dropdown never
              // asserts on a value that's no longer in Master Facilities.
              if (_selectedProductionArea.isNotEmpty &&
                  !_productionAreaOptions.contains(_selectedProductionArea))
                DropdownMenuItem(
                    value: _selectedProductionArea,
                    child: Text(_selectedProductionArea,
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText),
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              if (v == null || v == _selectedProductionArea) return;
              // On a block centre this is not a filter over the current page —
              // it chooses which production area's dashboard is being set up,
              // so the form is emptied and that area's own configuration is
              // loaded before anything can be saved onto it. Lot 237 itself,
              // and every other real plant, treat this as a plain filter.
              if (_isLot237BlockScope) {
                _onProductionAreaCentreChanged(v);
              } else {
                setState(() => _selectedProductionArea = v);
              }
            },
          ),
          const SizedBox(width: 16),
          filterDropdown<String>(
            label: 'Mapping Progress',
            value: _mappingFilter,
            items: _PlantEnergyCommandCenterSettingWidgetState._mappingFilterOptions
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText)),
                    ))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => _mappingFilter = v); },
          ),
        ],
      ),
    );
  }

  // ── Status / saving banner ─────────────────────────────────────────────────

  Widget _buildWarningBanner(BuildContext context) {
    if (_isSaving) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: const Color(0x1A6366F1),
        child: Row(children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 10),
          Text(_savingStatus.isEmpty ? 'Saving…' : _savingStatus,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: const Color(0xFF6366F1), fontWeight: FontWeight.w500)),
        ]),
      );
    }
    if (_saveMessage != null) {
      final isSuccess = _saveSuccess;
      final color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      final bg    = isSuccess ? const Color(0x1A10B981) : const Color(0x1AEF4444);
      final icon  = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: bg,
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(_saveMessage!,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ]),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Progress summary card ──────────────────────────────────────────────────

  Widget _buildProgressCard(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final pct   = _totalWidgets == 0 ? 0.0 : _mappedWidgets / _totalWidgets;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('MAPPING PROGRESS',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.6,
                    color: theme.primaryText)),
            const Spacer(),
            Text('$_mappedWidgets / $_totalWidgets widgets configured',
                style: GoogleFonts.poppins(fontSize: 13.5, color: theme.txtTertiary)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: kCyber.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? const Color(0xFF10B981) : kCyber,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _badgeChip('${(pct * 100).toStringAsFixed(0)}% complete', theme.primary),
            const SizedBox(width: 8),
            _badgeChip('$_mappedWidgets mapped', const Color(0xFF10B981)),
            const SizedBox(width: 8),
            if (_unmappedWidgets > 0)
              _badgeChip('$_unmappedWidgets unmapped', const Color(0xFFF59E0B)),
          ]),
        ],
      ),
    );
  }

  Widget _badgeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 6)],
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12.5, letterSpacing: 0.3, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ── Section card ───────────────────────────────────────────────────────────

  Widget _buildSection(BuildContext context, _Section section) {
    final theme = FlutterFlowTheme.of(context);

    final visibleWidgets = section.widgets.where((w) {
      if (_mappingFilter == 'Mapped')   return w.isMapped;
      if (_mappingFilter == 'Unmapped') return !w.isMapped;
      return true;
    }).toList();

    if (visibleWidgets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: section.iconBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: section.iconColor.withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: section.iconColor.withOpacity(0.2), blurRadius: 8)],
                ),
                child: Icon(section.icon, size: 22, color: section.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                            color: theme.primaryText)),
                    const SizedBox(height: 2),
                    Text(section.subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: theme.txtTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // The floor map is the one section that can grow: a plant adds
              // machines, and adding one should not need a release.
              if (section.canAddMachines) ...[
                TextButton.icon(
                  onPressed: () => _addMachine(section),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add machine',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
              ],
              _badgeChip(
                '${section.mappedCount}/${section.widgets.length}',
                section.allMapped ? const Color(0xFF10B981) : kCyber,
              ),
            ]),
          ),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          _buildColumnHeaders(context),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          ...visibleWidgets.map((w) => _buildWidgetRow(context, w)),
        ],
      ),
    );
  }

  // ── Column headers ─────────────────────────────────────────────────────────

  Widget _buildColumnHeaders(BuildContext context) {
    const cols  = ['Widget / Metric', 'Device Source', 'Data Field', 'Unit', 'Status'];
    const flex  = [3, 3, 3, 1, 2];

    return Container(
      color: kCyber.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: List.generate(cols.length, (i) => Expanded(
          flex: flex[i],
          child: Text(cols[i].toUpperCase(),
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: kCyber.withOpacity(0.9), letterSpacing: 0.6)),
        )),
      ),
    );
  }

  // ── Widget mapping row ─────────────────────────────────────────────────────

  /// Never show technical keys like `consumer[0]` under the widget name.
  /// blockA -> "Block A", gridImport -> "Grid import", total_consumption ->
  /// "Total consumption". Splits camelCase and underscores, then sentence-cases.
  String _humaniseKeyPart(String raw) {
    final spaced = raw
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ')
        .trim();
    if (spaced.isEmpty) return '';
    // A trailing single capital is a block letter: "block A", not "block a".
    final words = spaced.split(RegExp(r'\s+')).map((w) {
      if (w.length == 1) return w.toUpperCase();
      return w;
    }).toList();
    final joined = words.join(' ');
    return '${joined[0].toUpperCase()}${joined.substring(1)}';
  }

  String _friendlyWidgetSubtitle(_WidgetMapping w) {
    final raw = w.locationKey.trim();
    final m = RegExp(r'^([A-Za-z_]+)\[(\d+)\]$').firstMatch(raw);
    if (m != null) {
      final kind = m.group(1)!.toLowerCase();
      final n = (int.tryParse(m.group(2)!) ?? 0) + 1;
      switch (kind) {
        case 'consumer':
          return 'Top Consumer #$n';
        case 'cost_drivers':
          return 'Cost Driver #$n';
        case 'performance':
          return 'Performance KPI #$n';
        case 'glance':
          return 'At a Glance #$n';
        case 'hero':
          return 'Hero KPI #$n';
        case 'insight':
          return 'Insight Rule #$n';
        case 'flowsummary':
          return 'Flow Summary #$n';
        default:
          return '${kind[0].toUpperCase()}${kind.substring(1)} #$n';
      }
    }
    // Dotted keys → "<where> · <what>", e.g. blockA.gridImport becomes
    // "Block A · Grid import". Only the tail used to be shown, so three
    // different cards all read "Total" / "GridImport" with no way to tell which
    // block on the dashboard they drove.
    if (raw.contains('.')) {
      final parts = raw.split('.');
      final where = _humaniseKeyPart(parts.first);
      final what = _humaniseKeyPart(parts.sublist(1).join(' '));
      if (what.isEmpty) return where;
      return where.isEmpty ? what : '$where · $what';
    }
    return raw;
  }

  /// Rows that describe a whole block rather than one reading.
  ///
  /// These are the only mappings that take several meters, because a block's
  /// grid import or solar is usually split across more than one.
  bool _isBlockCardKey(String key) {
    final k = key.trim().toLowerCase();
    return k.startsWith('blocka.') ||
        k.startsWith('blockb.') ||
        k.startsWith('blockc.');
  }

  Widget _buildWidgetRow(BuildContext context, _WidgetMapping w) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: w.iconBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: w.iconColor.withOpacity(0.35)),
                  ),
                  child: Icon(w.icon, size: 18, color: w.iconColor),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 32,
                        child: TextField(
                          controller: w.labelCtrl,
                          onChanged: (val) {
                            w.label = val.trim().isNotEmpty ? val : w.locationKey;
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            hintText: 'Display Name',
                            hintStyle: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary),
                            filled: true,
                            fillColor: theme.cardStroke.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: theme.cardStroke),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: theme.cardStroke.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: theme.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_friendlyWidgetSubtitle(w),
                          style: GoogleFonts.poppins(fontSize: 11, color: theme.txtTertiary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: w.isCalculated
                    ? _calcChip(context)
                    // A block is rarely one meter, so its rows take several and
                    // the dashboard sums them. Everything else stays a single
                    // pick.
                    : _isBlockCardKey(w.key)
                        ? _MultiDeviceChips(
                            devices: _devicesInScope,
                            value: w.selectedDevice,
                            isLoading: _isLoadingDevices,
                            displayNames: _deviceDisplayNames,
                            onChanged: (v) => setState(() {
                              w.selectedDevice = v;
                              if (v.isEmpty) w.selectedField = '';
                            }),
                          )
                        : _DeviceDropdown(
                        devices: _devicesInScope,
                        value: w.selectedDevice,
                        isLoading: _isLoadingDevices,
                        displayNames: _deviceDisplayNames,
                        onChanged: (v) => setState(() {
                          w.selectedDevice = v ?? '';
                          w.selectedField  = '';
                          if ((v ?? '').isNotEmpty) {
                            final currentLabel = w.labelCtrl.text.trim();
                            if (currentLabel.isEmpty ||
                                RegExp(r'^Top Consumer #?\d+$', caseSensitive: false).hasMatch(currentLabel) ||
                                currentLabel == w.locationKey) {
                              // Prefer Master Facilities display name, fall back to device ID.
                              final friendlyName = _deviceDisplayNames[v!] ?? v;
                              w.labelCtrl.text = friendlyName;
                              w.label = friendlyName;
                            }
                          }
                        }),
                      ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: w.isCalculated
                    ? const SizedBox.shrink()
                    : _FieldDropdown(
                        fields: w.availableFields,
                        value: w.selectedField,
                        onChanged: (v) => setState(() => w.selectedField = v ?? ''),
                      ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(w.unit,
                  style: GoogleFonts.poppins(fontSize: 13.5, color: theme.txtTertiary),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: _StatusIcon(isMapped: w.isMapped, isCalculated: w.isCalculated),
            ),
          ]),
        ),
        // Machines drawn on the centre picture can be placed and given their
        // own cards from here, so a new floor photo needs no code change.
        if (w.isPlaceable)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: _widgetPositionRow(theme, w)),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => setState(() => w.expanded = !w.expanded),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: w.expanded
                                ? kCyber
                                : theme.cardStroke.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        Text('${w.metrics.length} metrics',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color:
                                    w.expanded ? kCyber : theme.txtTertiary)),
                        const SizedBox(width: 4),
                        Icon(
                            w.expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: w.expanded ? kCyber : theme.txtTertiary),
                      ]),
                    ),
                  ),
                ]),
                if (w.expanded) _buildMachineMetricTable(context, w),
              ],
            ),
          ),
        Divider(height: 1, color: kCyber.withOpacity(0.1)),
      ],
    );
  }

  // ── Calculated chip ────────────────────────────────────────────────────────

  Widget _calcChip(BuildContext context) {
    const costAccent = Color(0xFFEAB308);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: costAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: costAccent.withOpacity(0.5), width: 1.2),
        boxShadow: [BoxShadow(color: costAccent.withOpacity(0.14), blurRadius: 8)],
      ),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Container(width: 3, height: 40, color: costAccent.withOpacity(0.8)),
        const SizedBox(width: 10),
        const Icon(Icons.auto_awesome, size: 15, color: costAccent),
        const SizedBox(width: 7),
        Expanded(
          child: Text('Auto-calculated',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: costAccent, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ── Dashboard Branding section ─────────────────────────────────────────────

  Widget _buildBrandingSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x22F59E0B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.2), blurRadius: 8)],
                ),
                child: const Icon(Icons.palette_outlined, size: 22, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard Branding',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                            color: theme.primaryText)),
                    const SizedBox(height: 2),
                    Text('Customise the visual identity of the live dashboard',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: theme.txtTertiary)),
                  ],
                ),
              ),
              _badgeChip(
                '$_brandingMappedCount/3',
                _brandingMappedCount == 3 ? const Color(0xFF10B981) : kCyber,
              ),
            ]),
          ),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          _buildBrandingRow(
            context,
            label: 'Aerial Background Photo',
            subtitle: 'Shown behind the hero banner. JPG or PNG, max 5 MB.',
            child: _buildPhotoUploadRow(context),
          ),
          _buildBrandingRow(
            context,
            label: 'Logo',
            subtitle: 'Shown in the top-left badge. Leave empty to keep the '
                'initials of the organisation name.',
            child: _buildLogoUploadRow(context),
          ),
          _buildBrandingRow(
            context,
            label: 'Building Label Text',
            subtitle: 'Short name displayed in the dashboard header.',
            child: _buildBuildingLabelField(context),
          ),
          _buildBrandingRow(
            context,
            label: 'Top Bar Text',
            subtitle:
                'The strapline and centre title across the top of the live '
                'dashboard. Leave blank to keep the defaults.',
            child: _buildTopBarTextFields(context),
          ),
          _buildBrandingRow(
            context,
            label: 'Top Bar Branding',
            subtitle: 'Organisation name shown in the Kanban top bar. The logo '
                'badge takes its initials from this name.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBarDropdown(context),
                if (_topBarBranding ==
                    _PlantEnergyCommandCenterSettingWidgetState
                        ._kCustomBranding) ...[
                  const SizedBox(height: 10),
                  _buildCustomBrandingField(context),
                ],
              ],
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingRow(BuildContext context, {
    required String label,
    required String subtitle,
    required Widget child,
    bool isLast = false,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 14.5, fontWeight: FontWeight.w600,
                            color: theme.primaryText)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: theme.txtTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: child),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: theme.cardStroke),
      ],
    );
  }

  // ── Photo upload row ───────────────────────────────────────────────────────

  Widget _buildPhotoUploadRow(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (_brandingPhotoBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_brandingPhotoBytes!,
                  width: 80, height: 52, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
          ] else if (_brandingPhotoName.isNotEmpty) ...[
            Container(
              width: 80, height: 52,
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.cardStroke),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 20, color: theme.txtMuted),
                  Text('saved',
                      style: GoogleFonts.poppins(fontSize: 9, color: theme.txtMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          _OutlinedBtn(
            label: _isUploadingPhoto
                ? 'Uploading…'
                : (_brandingPhotoBytes != null || _brandingPhotoName.isNotEmpty)
                    ? 'Change Photo'
                    : 'Upload Photo',
            icon: Icons.upload_outlined,
            isLoading: _isUploadingPhoto,
            onTap: _pickAndValidateBrandingPhoto,
          ),
          if (_brandingPhotoName.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _brandingPhotoName,
                style: GoogleFonts.poppins(fontSize: 11, color: theme.txtTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ]),
        if (_brandingPhotoError != null) ...[
          const SizedBox(height: 6),
          Text(_brandingPhotoError!,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFFEF4444))),
        ],
      ],
    );
  }

  /// Free-text organisation name, shown only when the dropdown is on Custom.
  Widget _buildCustomBrandingField(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _customBrandingCtrl,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 14, color: theme.primaryText),
        decoration: InputDecoration(
          hintText: 'Organisation name, e.g. Kanabn Sdn Bhd',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted),
          filled: true,
          fillColor: theme.primaryBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.45))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.45))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: kCyber, width: 1.4)),
        ),
      ),
    );
  }

  /// Same shape as the aerial photo row, kept deliberately plain: pick a file,
  /// see its name, replace it.
  Widget _buildLogoUploadRow(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final has = _brandingLogoName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          OutlinedButton.icon(
            onPressed: _isUploadingLogo ? null : _pickBrandingLogo,
            icon: Icon(_isUploadingLogo
                ? Icons.hourglass_top
                : Icons.upload_file_outlined),
            label: Text(
              _isUploadingLogo
                  ? 'Uploading…'
                  : (has ? 'Replace logo' : 'Choose logo'),
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: kCyber,
              side: BorderSide(color: kCyber.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              has ? _brandingLogoName : 'No logo chosen — initials will be used',
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: has ? theme.primaryText : theme.txtMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (has)
            IconButton(
              tooltip: 'Remove logo',
              onPressed: () => setState(() {
                _brandingLogoBytes = null;
                _brandingLogoName = '';
                _existingLogoUrl = null;
              }),
              icon: const Icon(Icons.close, size: 17),
              color: theme.txtTertiary,
              splashRadius: 18,
            ),
        ]),
        if (_brandingLogoError != null) ...[
          const SizedBox(height: 6),
          Text(_brandingLogoError!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFFFF5D6C))),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: TextField(
            controller: _logoUrlCtrl,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 13, color: theme.primaryText),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.link, size: 16, color: theme.txtTertiary),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 34, minHeight: 34),
              hintText: 'or paste a logo image URL',
              hintStyle:
                  GoogleFonts.poppins(fontSize: 12.5, color: theme.txtMuted),
              filled: true,
              fillColor: theme.primaryBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: kCyber.withOpacity(0.45))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: kCyber.withOpacity(0.45))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: kCyber, width: 1.3)),
            ),
          ),
        ),
      ],
    );
  }

  /// Legacy sections the pin-sourced panels replace.
  ///
  /// These mapped a device per widget, which is exactly what the pins exist to
  /// stop: a summary that reads its own meter can disagree with the sites
  /// printed beside it, and nothing on screen explains the difference. They are
  /// hidden rather than deleted — their saved mappings are still written back
  /// on save, so switching back costs nothing.
  bool _isReplacedByPanel(String title) {
    if (title == 'Cost Drivers (Left Panel)') return true;
    if (_isPerFactoryScope) return false;
    const replaced = {
      'Hero Summary (Top Banner)',
      'Plant Performance (Right Panel)',
      'Today at a Glance (Bottom Row)',
    };
    return replaced.contains(title);
  }

  // ── Summary panels ─────────────────────────────────────────────────────────

  /// A summary panel and its cards.
  ///
  /// Every row here picks one of the pin metrics; there is deliberately no
  /// device dropdown. A panel that mapped its own meter could disagree with the
  /// pins printed beside it, which is exactly what these screens used to do.
  Widget _buildPanelSection(BuildContext context, _PanelSpec spec) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x1A22D3EE),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: const Color(0xFF22D3EE).withOpacity(0.4)),
                ),
                child: Icon(spec.icon, size: 22, color: const Color(0xFF22D3EE)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.title,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText)),
                    const SizedBox(height: 2),
                    Text(spec.subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: theme.txtTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _badgeChip(spec.badge, const Color(0xFF9A6BFF)),
            ]),
          ),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          _buildPanelHeaders(context, spec.kind),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          for (final c in spec.cards) _buildPanelRow(context, spec, c),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Values come from the Cost Driver Pins above — no panel maps its '
              'own device.',
              style:
                  GoogleFonts.poppins(fontSize: 11.5, color: theme.txtMuted),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _panelHeaderLabels(_PanelKind kind) {
    switch (kind) {
      case _PanelKind.rank:
        return ['CARD', 'DISPLAY LABEL', 'RANK BY', 'METRIC (FROM PINS)', 'UNIT', 'DIRECTION'];
      case _PanelKind.series:
        return ['SERIES', 'DISPLAY LABEL', 'AGGREGATION', 'METRIC (FROM PINS)', 'UNIT', 'INTERVAL'];
      case _PanelKind.total:
        return ['CARD', 'DISPLAY LABEL', 'AGGREGATION', 'METRIC (FROM PINS)', 'UNIT', 'COMPUTE'];
    }
  }

  Widget _buildPanelHeaders(BuildContext context, _PanelKind kind) {
    const flex = [2, 4, 3, 4, 1, 3];
    final headers = _panelHeaderLabels(kind);
    return Container(
      color: kCyber.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: List.generate(
          headers.length,
          (i) => Expanded(
            flex: flex[i],
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(headers[i],
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kCyber.withOpacity(0.85),
                      letterSpacing: 0.7)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelRow(
      BuildContext context, _PanelSpec spec, _PanelCard c) {
    final theme = FlutterFlowTheme.of(context);
    const flex = [2, 4, 3, 4, 1, 3];

    Widget cell(int i, Widget child) => Expanded(
          flex: flex[i],
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: child,
          ),
        );

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          cell(
            0,
            Text(c.key.split('.').last,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText),
                overflow: TextOverflow.ellipsis),
          ),
          cell(
            1,
            SizedBox(
              height: 38,
              child: TextField(
                controller: c.labelCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(
                    fontSize: 13, color: theme.primaryText),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.primaryBackground,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: kCyber.withOpacity(0.45))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: kCyber.withOpacity(0.45))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: kCyber, width: 1.4)),
                ),
              ),
            ),
          ),
          cell(
            2,
            spec.kind == _PanelKind.rank
                ? _panelDropdown(theme, _kPanelRankBy, c.rankBy,
                    (v) => setState(() => c.rankBy = v))
                : _panelDropdown(theme, _kPanelAggregations, c.agg,
                    (v) => setState(() => c.agg = v)),
          ),
          cell(
            3,
            _panelMetricDropdown(theme, c),
          ),
          cell(
            4,
            SizedBox(
              height: 38,
              child: TextField(
                controller: c.unitCtrl,
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: theme.primaryText),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.primaryBackground,
                  // The metric's own unit as the placeholder, so leaving it
                  // blank visibly means "whatever this metric reports in".
                  hintText: c.defaultUnit.isEmpty ? '—' : c.defaultUnit,
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12.5, color: theme.txtTertiary),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                          color: theme.primary.withOpacity(0.25))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                          color: theme.primary.withOpacity(0.25))),
                ),
              ),
            ),
          ),
          cell(
            5,
            switch (spec.kind) {
              _PanelKind.rank => _panelDropdown(theme, _kPanelDirections,
                  c.direction, (v) => setState(() => c.direction = v)),
              _PanelKind.series => _panelDropdown(theme, _kPanelIntervals,
                  c.interval, (v) => setState(() => c.interval = v)),
              _PanelKind.total => Container(
                  height: 38,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x149A6BFF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0x4D9A6BFF)),
                  ),
                  child: Text('from pins',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A6BFF))),
                ),
            },
          ),
        ]),
      ),
      Divider(height: 1, color: kCyber.withOpacity(0.1)),
    ]);
  }

  Widget _panelDropdown(FlutterFlowTheme theme, List<String> options,
      String value, void Function(String) onChanged) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kCyber.withOpacity(0.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          isDense: true,
          dropdownColor: theme.primaryBackground,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: theme.txtTertiary),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: theme.primaryText),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }

  Widget _panelMetricDropdown(FlutterFlowTheme theme, _PanelCard c) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kCyber.withOpacity(0.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: c.metricKey.isEmpty ? null : c.metricKey,
          isExpanded: true,
          isDense: true,
          dropdownColor: theme.primaryBackground,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: theme.txtTertiary),
          items: _kPinCardMetrics
              .map((o) => DropdownMenuItem(
                    value: o.key,
                    child: Row(children: [
                      Icon(o.icon, size: 14, color: theme.txtTertiary),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(o.label,
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: theme.primaryText),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ))
              .toList(),
          onChanged: (v) => setState(() => c.metricKey = v ?? c.metricKey),
        ),
      ),
    );
  }

  // ── Top bar text fields ────────────────────────────────────────────────────

  /// The strapline and the centre title of the live dashboard. Both were
  /// literals in the dashboard widget, so naming a new site meant editing code
  /// and shipping a build.
  Widget _buildTopBarTextFields(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    Widget labelled(String label, String hint, TextEditingController ctrl) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.txtTertiary)),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: ctrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: theme.txtMuted),
                    filled: true,
                    fillColor: theme.primaryBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            BorderSide(color: kCyber.withOpacity(0.45))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            BorderSide(color: kCyber.withOpacity(0.45))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            const BorderSide(color: kCyber, width: 1.4)),
                  ),
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [
        labelled('TOP BAR SUB-LABEL', 'e.g. ENERGY COST MANAGEMENT CENTER',
            _topBarSubLabelCtrl),
        const SizedBox(width: 14),
        labelled('DASHBOARD TITLE', 'e.g. ENERGY COMMAND CENTER',
            _dashTitleCtrl),
      ]),
    );
  }

  // ── Building label field ───────────────────────────────────────────────────

  Widget _buildBuildingLabelField(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SizedBox(
      height: 40,
      child: TextField(
        controller: _buildingLabelCtrl,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 14, color: theme.primaryText),
        decoration: InputDecoration(
          hintText: 'e.g. Block A Factory',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted),
          filled: true,
          fillColor: theme.primaryBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.45), width: 1.2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.45), width: 1.2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: kCyber, width: 1.4)),
        ),
      ),
    );
  }

  // ── Top bar branding dropdown ──────────────────────────────────────────────

  Widget _buildTopBarDropdown(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      height: 40,
      decoration: cyberField(theme),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Container(width: 3, height: 40, color: kCyber.withOpacity(0.8)),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _topBarBranding.isEmpty ? null : _topBarBranding,
              isExpanded: true,
              isDense: true,
              padding: const EdgeInsets.only(left: 12, right: 10),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kCyber),
              dropdownColor: theme.secondaryBackground,
              hint: Text('Select branding…',
                  style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
              items: _PlantEnergyCommandCenterSettingWidgetState._brandingOptions
                  .map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(opt,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: theme.primaryText)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _topBarBranding = v ?? ''),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(children: [
      Text(
        '$_mappedWidgets of $_totalWidgets widgets configured • $_unmappedWidgets remaining',
        style: GoogleFonts.poppins(fontSize: 13.5, color: theme.txtTertiary),
      ),
      const Spacer(),
      _OutlinedBtn(
        label: 'Reset',
        icon: Icons.restart_alt_outlined,
        onTap: () {
          for (final sec in _sections) {
            for (final w in sec.widgets) {
              w.selectedDevice = '';
              w.selectedField  = '';
            }
          }
          _buildingLabelCtrl.clear();
          setState(() {
            _topBarBranding     = '';
            _brandingPhotoBytes = null;
            _brandingPhotoName  = '';
            _brandingPhotoError = null;
          });
        },
      ),
      const SizedBox(width: 12),
      _PrimaryBtn(
        label: _isSaving
            ? _savingStatus
            : (widget.embedded ? 'Save & View Overview' : 'Save Configuration'),
        icon: Icons.save_outlined,
        isLoading: _isSaving,
        onTap: _save,
      ),
    ]);
  }

  Widget _buildPinSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final List<Widget> visibleRows = [];
    // Was a fixed 8. Counting the pins that exist means the badge still reads
    // correctly once sites can be added and removed.
    final int totalCount = _pins.length;
    int mappedCount = 0;

    for (int i = 0; i < totalCount; i++) {
      final p = _pins[i];
      final isMapped = p.isMapped;
      if (isMapped) mappedCount++;

      // Filter mapping status
      if (_mappingFilter == 'Mapped' && !isMapped) continue;
      if (_mappingFilter == 'Unmapped' && isMapped) continue;

      visibleRows.add(_buildLotSiteRow(context, i, p));
    }

    final allMapped = mappedCount == totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Section header —
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x1A22D3EE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.2), blurRadius: 8)],
                ),
                child: const Icon(Icons.pin_drop_outlined, size: 22, color: Color(0xFF22D3EE)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COST DRIVER PINS',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            letterSpacing: 0.3, color: theme.primaryText)),
                    const SizedBox(height: 2),
                    Text(
                      'Map each site pin to a device or TNB meter — drives the group energy dashboard pins',
                      style: GoogleFonts.poppins(fontSize: 13, color: theme.txtTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _addCostDriverPin,
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add cost driver',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              _badgeChip(
                '$mappedCount/$totalCount',
                allMapped ? const Color(0xFF10B981) : kCyber,
              ),
            ]),
          ),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          _buildHeroPositionRow(context),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          _buildPinColumnHeaders(context),
          Divider(height: 1, color: kCyber.withOpacity(0.15)),
          if (visibleRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No pins matching this filter',
                    style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
              ),
            )
          else
            ...visibleRows,
        ],
      ),
    );
  }

  /// The centre card's place on the group map, set the same way as a pin's:
  /// percentages of the aerial photo, with the card's top-left corner at the
  /// point. It stays in the middle until moved.
  Widget _buildHeroPositionRow(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final placed = _heroXCtrl.text.trim().isNotEmpty ||
        _heroYCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(children: [
        Text('CENTER CARD POSITION',
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: kCyber.withOpacity(0.85))),
        const SizedBox(width: 14),
        SizedBox(width: 110, child: _pinPctField(theme, _heroXCtrl, 'X %')),
        const SizedBox(width: 10),
        SizedBox(width: 110, child: _pinPctField(theme, _heroYCtrl, 'Y %')),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: placed
              ? () => setState(() {
                    _heroXCtrl.text = '';
                    _heroYCtrl.text = '';
                  })
              : null,
          icon: const Icon(Icons.restart_alt, size: 15),
          label: Text('Reset position',
              style: GoogleFonts.poppins(
                  fontSize: 11.5, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            foregroundColor: kCyber,
            disabledForegroundColor: theme.txtMuted.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Percentages of the aerial photo (0-100); both are needed. Leave '
            'blank to keep it in the middle. What the card shows is set by '
            'clicking the card itself on the dashboard, not here.',
            style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted),
          ),
        ),
      ]),
    );
  }

  /// Adds a site to the map.
  ///
  /// The dashboard used to carry a fixed six, with their keys and their
  /// positions written into the code, so adding a lot meant an edit and a
  /// release. New pins take the next free key and are positioned from the
  /// settings page instead.
  void _addCostDriverPin() {
    final used = _pins.map((p) => p.pinIndex).toSet();
    var idx = 0;
    while (used.contains(idx)) {
      idx++;
    }
    setState(() {
      _pins.add(_PinMapping(
        key: 'pin[$idx]',
        pinIndex: idx,
        defaultLabel: 'Cost Driver ${_pins.length + 1}',
        isRemovable: true,
      ));
    });
  }

  Widget _buildPinColumnHeaders(BuildContext context) {
    // Named as the mockup names them, so a column on screen and a column in
    // the spec can be matched without translating between the two.
    const headers = [
      'WIDGET', 'DISPLAY NAME',
      'CHANNEL MAPPING — DATA SCOPE',
      'CHANNEL MAPPING — METRIC FIELD',
      'UNIT', '', 'METRICS',
    ];
    const flex = [3, 3, 4, 4, 1, 1, 1];

    return Container(
      color: kCyber.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: List.generate(headers.length, (i) => Expanded(
          flex: flex[i],
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(headers[i],
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: kCyber.withOpacity(0.85), letterSpacing: 0.7)),
          ),
        )),
      ),
    );
  }

  Widget _buildLotSiteRow(BuildContext context, int index, _PinMapping p) {
    final theme = FlutterFlowTheme.of(context);
    final boxColor = index < 4 ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            // Col 1 — Widget
            Expanded(
              flex: 3,
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: boxColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: boxColor.withOpacity(0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: const Color(0xFF60A5FA))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(p.defaultLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 13.5, fontWeight: FontWeight.w600,
                                  color: theme.primaryText),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (p.isCurrentSite) ...[
                          const SizedBox(width: 5),
                          Text('(current site)',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ]),
                      Text(p.key,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5, color: theme.txtTertiary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
            // Col 2 — Display Name
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: p.displayNameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(fontSize: 13.5, color: theme.primaryText),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.primaryBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: kCyber.withOpacity(0.45), width: 1.2)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: kCyber.withOpacity(0.45), width: 1.2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: kCyber, width: 1.4)),
                    ),
                  ),
                ),
              ),
            ),
            // Col 3 — Data Scope (Site Dropdown)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _SiteDropdown(
                  sites: _tnbSiteOptions,
                  value: p.selectedSiteId,
                  isLoading: _isLoadingSites,
                  onChanged: (id, label) => setState(() {
                    p.selectedSiteId = id ?? '';
                    p.selectedSiteLabel = label;
                  }),
                ),
              ),
            ),
            // Col 4 — Metric Field (Metric Dropdown)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _MetricDropdown(
                  value: p.selectedMetric,
                  onChanged: (v) => setState(() => p.selectedMetric = v ?? ''),
                ),
              ),
            ),
            // Col 5 — Unit
            Expanded(
              flex: 1,
              child: Text(p.unit,
                  style: GoogleFonts.poppins(fontSize: 13, color: theme.txtTertiary),
                  overflow: TextOverflow.ellipsis),
            ),
            // Col 6 — remove a pin the user added
            SizedBox(
              width: 34,
              child: p.isRemovable
                  ? IconButton(
                      tooltip: 'Remove this cost driver',
                      onPressed: () => setState(() {
                        _pins.remove(p);
                        p.dispose();
                      }),
                      icon: const Icon(Icons.close, size: 16),
                      color: theme.txtTertiary,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 30, height: 30),
                    )
                  : const SizedBox.shrink(),
            ),
            // Col 7 — open this pin's dashboard cards
            SizedBox(
              width: 40,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => setState(() => p.expanded = !p.expanded),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: p.expanded
                            ? kCyber
                            : theme.cardStroke.withOpacity(0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    p.expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: p.expanded ? kCyber : theme.txtTertiary,
                  ),
                ),
              ),
            ),
          ]),
        ),
        if (p.expanded) _buildPinMetricTable(context, p),
        Divider(height: 1, color: kCyber.withOpacity(0.1)),
      ],
    );
  }

  /// The cards one pin shows on the group dashboard.
  ///
  /// A pin used to render two fixed figures, cost and energy, so showing Max
  /// Demand or Solar for a site meant changing code. Each row here is one
  /// card: its label, the colour of its icon, and which value it reads.
  Widget _buildPinMetricTable(BuildContext context, _PinMapping p) {
    final theme = FlutterFlowTheme.of(context);
    final atLimit = p.metrics.length >= kMaxPinMetrics;

    return Container(
      color: kCyber.withOpacity(0.03),
      padding: const EdgeInsets.fromLTRB(72, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which solar device belongs to this site. Without it a solar card on
          // this pin has nothing to read: its main meter measures grid import.
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Row(children: [
              Text('SOLAR DEVICE',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: kCyber.withOpacity(0.85))),
              const SizedBox(width: 14),
              SizedBox(
                width: 320,
                child: _DeviceDropdown(
                  devices: _devices,
                  value: p.selectedSolarDevice,
                  isLoading: _isLoadingDevices,
                  displayNames: _deviceDisplayNames,
                  onChanged: (v) =>
                      setState(() => p.selectedSolarDevice = v ?? ''),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Leave empty when this site has no solar. The solar card then '
                  'reads as a dash rather than reporting its grid meter.',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted),
                ),
              ),
            ]),
          ),
          // Position on the aerial photo. Percentages rather than pixels so the
          // pin stays put whatever size the dashboard is drawn at.
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Row(children: [
              Text('POSITION ON MAP',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: kCyber.withOpacity(0.85))),
              const SizedBox(width: 14),
              SizedBox(width: 110, child: _pinPctField(theme, p.xCtrl, 'X %')),
              const SizedBox(width: 10),
              SizedBox(width: 110, child: _pinPctField(theme, p.yCtrl, 'Y %')),
              const SizedBox(width: 10),
              // Clearing both fields is what returns a pin to where it started,
              // and that is not discoverable by looking at two text boxes.
              TextButton.icon(
                onPressed: (p.xCtrl.text.trim().isEmpty &&
                        p.yCtrl.text.trim().isEmpty)
                    ? null
                    : () => setState(() {
                          p.xCtrl.text = '';
                          p.yCtrl.text = '';
                        }),
                icon: const Icon(Icons.restart_alt, size: 15),
                label: Text('Reset position',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: kCyber,
                  disabledForegroundColor: theme.txtMuted.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Percentages of the aerial photo (0-100). Leave blank to keep '
                  'the built-in position.',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: theme.txtMuted),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Text(
                'METRIC FIELD MAPPING - ${p.metrics.length} DASHBOARD CARDS',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: kCyber.withOpacity(0.85)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      height: 1, color: theme.cardStroke.withOpacity(0.25))),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: atLimit
                    ? null
                    : () => setState(() => p.metrics
                        .add(_PinMetric(metricKey: _firstUnusedMetric(p)))),
                icon: const Icon(Icons.add, size: 15),
                label: Text(
                  atLimit ? 'Max $kMaxPinMetrics cards' : 'Add card',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  disabledForegroundColor: theme.txtMuted.withOpacity(0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ]),
          ),
          if (p.metrics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No cards configured - this pin keeps showing cost and energy only.',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: theme.txtMuted),
              ),
            )
          else
            for (int i = 0; i < p.metrics.length; i++)
              _buildPinMetricRow(context, p, i),
        ],
      ),
    );
  }

  /// Adds a machine to the floor map.
  ///
  /// Keys continue the `consumer[n]` series the dashboard already reads, so a
  /// new machine is picked up by the same code that resolves the original six
  /// — no separate path, and nothing to keep in step later.
  void _addMachine(_Section section) {
    var idx = 0;
    final used = <int>{};
    for (final w in section.widgets) {
      final m = RegExp(r'consumer\[(\d+)\]').firstMatch(w.key);
      if (m != null) used.add(int.parse(m.group(1)!));
    }
    while (used.contains(idx)) {
      idx++;
    }
    setState(() {
      section.widgets.add(_WidgetMapping(
        key: 'consumer[$idx]',
        label: 'Machine #${section.widgets.length + 1}',
        locationKey: 'Machine #${section.widgets.length + 1}',
        icon: Icons.precision_manufacturing,
        iconBg: const Color(0x1AF43F5E),
        iconColor: const Color(0xFFF43F5E),
        unit: 'kW',
        availableFields: section.widgets.isNotEmpty
            ? section.widgets.first.availableFields
            : const [],
      ));
    });
  }

  /// The cards one machine shows on the floor map.
  ///
  /// Deliberately the same table as a map pin's: one screen teaching two is
  /// better than two screens each with their own idea of what a card is.
  Widget _buildMachineMetricTable(BuildContext context, _WidgetMapping w) {
    final theme = FlutterFlowTheme.of(context);
    final atLimit = w.metrics.length >= kMaxPinMetrics;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: kCyber.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Text(
                'METRIC FIELD MAPPING - ${w.metrics.length} FLOOR MAP CARDS',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: kCyber.withOpacity(0.85)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      height: 1, color: theme.cardStroke.withOpacity(0.25))),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: atLimit
                    ? null
                    : () => setState(() {
                          final used =
                              w.metrics.map((m) => m.metricKey).toSet();
                          final next = _kPinCardMetrics
                              .firstWhere((o) => !used.contains(o.key),
                                  orElse: () => _kPinCardMetrics.first)
                              .key;
                          w.metrics.add(_PinMetric(metricKey: next));
                        }),
                icon: const Icon(Icons.add, size: 15),
                label: Text(atLimit ? 'Max $kMaxPinMetrics cards' : 'Add card',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  disabledForegroundColor: theme.txtMuted.withOpacity(0.4),
                ),
              ),
            ]),
          ),
          if (w.metrics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No cards configured - this machine keeps its single value.',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: theme.txtMuted),
              ),
            )
          else
            for (int i = 0; i < w.metrics.length; i++)
              _buildMachineMetricRow(context, w, i),
        ],
      ),
    );
  }

  Widget _buildMachineMetricRow(
      BuildContext context, _WidgetMapping w, int i) {
    final theme = FlutterFlowTheme.of(context);
    final m = w.metrics[i];

    Widget field(String label, Widget child, int flex) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: theme.txtTertiary)),
                const SizedBox(height: 5),
                child,
              ],
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.cardStroke.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 8),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: kCyber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text('${i + 1}',
                  style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: kCyber)),
            ),
          ),
          field(
            'DISPLAY LABEL',
            SizedBox(
              height: 34,
              child: TextField(
                controller: m.labelCtrl,
                onChanged: (_) => setState(() {}),
                style:
                    GoogleFonts.poppins(fontSize: 12, color: theme.primaryText),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.primaryBackground,
                  hintText: m.option?.label ?? '',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, color: theme.txtMuted.withOpacity(0.5)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: kCyber.withOpacity(0.35))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: kCyber.withOpacity(0.35))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: kCyber, width: 1.3)),
                ),
              ),
            ),
            4,
          ),
          field('COLOR', _pinMetricColorDropdown(theme, m), 2),
          field('METRIC FIELD', _pinMetricFieldDropdown(theme, m), 4),
          field(
            'UNIT',
            Container(
              height: 34,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.primaryBackground.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.cardStroke.withOpacity(0.25)),
              ),
              child: Text(m.unit.isEmpty ? '-' : m.unit,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: theme.txtTertiary)),
            ),
            2,
          ),
          field('FORMAT', _pinMetricFormatDropdown(theme, m), 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IconButton(
              tooltip: 'Remove card',
              onPressed: () => setState(() => w.metrics.removeAt(i).dispose()),
              icon: const Icon(Icons.close, size: 16),
              color: theme.txtTertiary,
              splashRadius: 18,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Position fields for a machine drawn on the centre picture. Same idea as a
  /// map pin: percentages of the picture, blank meaning "leave it where it was".
  Widget _widgetPositionRow(FlutterFlowTheme theme, _WidgetMapping w) {
    return Row(children: [
      Text('POSITION',
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: kCyber.withOpacity(0.8))),
      const SizedBox(width: 10),
      SizedBox(width: 92, child: _pinPctField(theme, w.xCtrl, 'X %')),
      const SizedBox(width: 8),
      SizedBox(width: 92, child: _pinPctField(theme, w.yCtrl, 'Y %')),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: (w.xCtrl.text.trim().isEmpty && w.yCtrl.text.trim().isEmpty)
            ? null
            : () => setState(() {
                  w.xCtrl.text = '';
                  w.yCtrl.text = '';
                }),
        icon: const Icon(Icons.restart_alt, size: 14),
        label: Text('Reset',
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          foregroundColor: kCyber,
          disabledForegroundColor: theme.txtMuted.withOpacity(0.4),
        ),
      ),
      Expanded(
        child: Text(
          'Percentages of the centre picture (0-100). Blank keeps the built-in spot.',
          style: GoogleFonts.poppins(fontSize: 10.5, color: theme.txtMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

  Widget _pinPctField(
      FlutterFlowTheme theme, TextEditingController ctrl, String hint) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryText),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: theme.primaryBackground,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: 12, color: theme.txtMuted.withOpacity(0.55)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.35))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.35))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: kCyber, width: 1.3)),
        ),
      ),
    );
  }

  /// The first metric this pin is not already showing, so adding a card does
  /// not silently duplicate the one above it.
  String _firstUnusedMetric(_PinMapping p) {
    final used = p.metrics.map((m) => m.metricKey).toSet();
    for (final o in _kPinCardMetrics) {
      if (!used.contains(o.key)) return o.key;
    }
    return _kPinCardMetrics.first.key;
  }

  Widget _buildPinMetricRow(BuildContext context, _PinMapping p, int i) {
    final theme = FlutterFlowTheme.of(context);
    final m = p.metrics[i];

    InputDecoration dec() => InputDecoration(
          isDense: true,
          filled: true,
          fillColor: theme.primaryBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.35))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: kCyber.withOpacity(0.35))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: kCyber, width: 1.3)),
        );

    Widget field(String label, Widget child, int flex) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: theme.txtTertiary)),
                const SizedBox(height: 5),
                child,
              ],
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.cardStroke.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 8),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: kCyber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text('${i + 1}',
                  style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: kCyber)),
            ),
          ),
          field(
            'DISPLAY LABEL',
            SizedBox(
              height: 34,
              child: TextField(
                controller: m.labelCtrl,
                onChanged: (_) => setState(() {}),
                style:
                    GoogleFonts.poppins(fontSize: 12, color: theme.primaryText),
                decoration: dec().copyWith(
                  hintText: m.option?.label ?? '',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, color: theme.txtMuted.withOpacity(0.5)),
                ),
              ),
            ),
            4,
          ),
          field('COLOR', _pinMetricColorDropdown(theme, m), 2),
          field('METRIC FIELD', _pinMetricFieldDropdown(theme, m), 4),
          field(
            'AGGREGATION',
            Container(
              height: 34,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x149A6BFF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x4D9A6BFF)),
              ),
              child: Text(m.agg,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A6BFF))),
            ),
            2,
          ),
          field(
            'UNIT',
            Container(
              height: 34,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.primaryBackground.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.cardStroke.withOpacity(0.25)),
              ),
              child: Text(m.unit.isEmpty ? '-' : m.unit,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: theme.txtTertiary)),
            ),
            2,
          ),
          field('FORMAT', _pinMetricFormatDropdown(theme, m), 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IconButton(
              tooltip: 'Remove card',
              onPressed: () =>
                  setState(() => p.metrics.removeAt(i).dispose()),
              icon: const Icon(Icons.close, size: 16),
              color: theme.txtTertiary,
              splashRadius: 18,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Decimal places. Unlike aggregation this really is a presentation choice:
  /// the same figure reads differently as 1,412 or 1,412.9 depending on what
  /// the screen is for.
  Widget _pinMetricFormatDropdown(FlutterFlowTheme theme, _PinMetric m) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kCyber.withOpacity(0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: m.effectiveDecimals,
          isExpanded: true,
          isDense: true,
          dropdownColor: theme.primaryBackground,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: theme.txtTertiary),
          items: _kPinMetricDecimals
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(
                        d == 0 ? '1,234' : '1,234.${'0' * d}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: theme.primaryText)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => m.decimals = v),
        ),
      ),
    );
  }

  Widget _pinMetricColorDropdown(FlutterFlowTheme theme, _PinMetric m) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kCyber.withOpacity(0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: m.colorKey,
          isExpanded: true,
          isDense: true,
          dropdownColor: theme.primaryBackground,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: theme.txtTertiary),
          items: _kPinMetricColors.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Row(children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: e.value, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(e.key,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: theme.primaryText)),
                    ]),
                  ))
              .toList(),
          onChanged: (v) => setState(() => m.colorKey = v ?? m.colorKey),
        ),
      ),
    );
  }

  Widget _pinMetricFieldDropdown(FlutterFlowTheme theme, _PinMetric m) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kCyber.withOpacity(0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: m.metricKey.isEmpty ? null : m.metricKey,
          isExpanded: true,
          isDense: true,
          hint: Text('Select metric...',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: theme.txtMuted.withOpacity(0.6))),
          dropdownColor: theme.primaryBackground,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: theme.txtTertiary),
          items: _kPinCardMetrics
              .map((o) => DropdownMenuItem(
                    value: o.key,
                    child: Row(children: [
                      Icon(o.icon, size: 14, color: theme.txtTertiary),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(o.label,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: theme.primaryText),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            m.metricKey = v ?? m.metricKey;
            // Let the new metric bring its own default rather than inheriting
            // three decimal places from a power factor.
            m.decimals = null;
          }),
        ),
      ),
    );
  }

  Widget _disabledDropdownCell(FlutterFlowTheme theme, String text) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.primaryBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.cardStroke.withOpacity(0.25)),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: theme.txtMuted.withOpacity(0.45)),
              overflow: TextOverflow.ellipsis),
        ),
        Icon(Icons.keyboard_arrow_down, size: 16, color: theme.txtMuted.withOpacity(0.3)),
      ]),
    );
  }
}
