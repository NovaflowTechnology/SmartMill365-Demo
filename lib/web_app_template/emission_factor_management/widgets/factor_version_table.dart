import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/rbac.dart';
import '../emission_factor_model.dart';

class FactorVersionTable extends StatelessWidget {
  final List<EmissionFactor> factors;
  final String userRole;
  final VoidCallback? onRefresh;
  final void Function(EmissionFactor)? onView;
  final void Function(EmissionFactor)? onActivate;
  final void Function(EmissionFactor)? onEdit;
  final void Function(EmissionFactor)? onDelete;

  const FactorVersionTable({
    super.key,
    required this.factors,
    this.userRole = '',
    this.onRefresh,
    this.onView,
    this.onActivate,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table header with note
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FACTOR VERSION HISTORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: t.secondaryText.withOpacity(0.6),
                ),
              ),
              Row(
                children: [
                  Text(
                    'One Active factor per fiscal year. Locked records are immutable.',
                    style: TextStyle(
                      fontSize: 11,
                      color: t.secondaryText.withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Refresh data',
                      child: InkWell(
                        onTap: onRefresh,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.refresh,
                            size: 16,
                            color: t.secondaryText.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Table container
        Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : t.primaryBackground.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLight ? const Color(0xFFE2E8F0) : t.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _headerRow(context, t, isLight),
                ...factors.map((f) => _dataRow(context, f, t, isLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerRow(BuildContext context, dynamic t, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : t.primaryBackground.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : t.primary.withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _headerCell('FISCAL YEAR', flex: 15, t: t, isLight: isLight),
          _headerCell('FACTOR (kgCO₂e/kWH)', flex: 16, t: t, isLight: isLight),
          _headerCell('CARBON COST (RM/tCO₂e)', flex: 16, t: t, isLight: isLight),
          _headerCell('SOURCE', flex: 20, t: t, isLight: isLight),
          _headerCell('PUBLISHED', flex: 18, t: t, isLight: isLight),
          _headerCell('EFFECTIVE FROM', flex: 16, t: t, isLight: isLight),
          _headerCell('STATUS', flex: 13, t: t, isLight: isLight),
          _headerCell('ACTIONS', flex: 16, t: t, isLight: isLight, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _headerCell(
    String label, {
    required int flex,
    required dynamic t,
    required bool isLight,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: t.secondaryText.withOpacity(0.55),
        ),
      ),
    );
  }

  Widget _dataRow(
    BuildContext context,
    EmissionFactor factor,
    dynamic t,
    bool isLight,
  ) {
    final isLast = factors.last.id == factor.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: factor.status == FactorStatus.active ? (isLight ? t.primary.withOpacity(0.03) : t.primary.withOpacity(0.04)) : Colors.transparent,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: isLight ? const Color(0xFFF1F5F9) : t.primary.withOpacity(0.06),
                  width: 1,
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fiscal Year
          Expanded(
            flex: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.fiscalYearLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLight ? const Color(0xFF1E293B) : t.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  factor.fiscalYearRange,
                  style: TextStyle(
                    fontSize: 11,
                    color: t.secondaryText.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          // Factor value
          Expanded(
            flex: 16,
            child: factor.isPending
                ? Row(
                    children: [
                      Text(
                        '— pending —',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: t.secondaryText.withOpacity(0.4),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        factor.factorDisplay,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: factor.status == FactorStatus.active ? t.primary : (isLight ? const Color(0xFF1E293B) : t.primaryText),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (factor.isPending)
                        const SizedBox.shrink()
                      else
                        Text(
                          'kgCO₂e / kWh',
                          style: TextStyle(
                            fontSize: 10,
                            color: t.secondaryText.withOpacity(0.4),
                          ),
                        ),
                      if (factor.isRestated) ...[
                        const SizedBox(width: 6),
                        _restatedBadge(t, isLight),
                      ],
                    ],
                  ),
          ),
          // Carbon Cost
          Expanded(
            flex: 16,
            child: Text(
              factor.carbonCostDisplay,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: factor.carbonCost != null
                    ? (isLight ? const Color(0xFF1E293B) : t.primaryText)
                    : t.secondaryText.withOpacity(0.4),
              ),
            ),
          ),
          // Source
          Expanded(
            flex: 20,
            child: factor.sourceChipLabel != null
                ? _sourceChip(factor.sourceChipLabel!, factor.status, t, isLight)
                : Text(
                    factor.source,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.secondaryText.withOpacity(0.6),
                    ),
                  ),
          ),

          const SizedBox(
            width: 85.0,
          ),
          // Published
          Expanded(
            flex: 18,
            child: Text(
              factor.publishedDisplay,
              style: TextStyle(
                fontSize: 13,
                color: t.secondaryText.withOpacity(0.65),
              ),
            ),
          ),
          // Effective From
          Expanded(
            flex: 16,
            child: Text(
              '01 Jan ${factor.fiscalYear}',
              style: TextStyle(
                fontSize: 13,
                color: t.secondaryText.withOpacity(0.65),
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 13,
            child: _statusChip(factor.status, t, isLight),
          ),
          // Actions
          Expanded(
            flex: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildActions(factor, t),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(EmissionFactor factor, dynamic t) {
    final isDraft  = factor.status == FactorStatus.draft;
    final isActive = factor.status == FactorStatus.active;
    final isLocked = factor.status == FactorStatus.locked;
    const m = AppRoles.kModuleEmissionFactorMgmt;

    final canActivate = isDraft &&
        AppRoles.canAction(userRole, m, AppRoles.kEmfActivate);
    final canEdit = (isDraft  && AppRoles.canAction(userRole, m, AppRoles.kEmfEditDraft))  ||
                   (isActive && AppRoles.canAction(userRole, m, AppRoles.kEmfEditActive)) ||
                   (isLocked && AppRoles.canAction(userRole, m, AppRoles.kEmfEditLocked));
    final canDelete = (isDraft  && AppRoles.canAction(userRole, m, AppRoles.kEmfDeleteDraft))  ||
                     (isActive && AppRoles.canAction(userRole, m, AppRoles.kEmfDeleteActive)) ||
                     (isLocked && AppRoles.canAction(userRole, m, AppRoles.kEmfDeleteLocked));

    String editTooltip = 'Edit';
    if (isActive) editTooltip = 'Edit Active (Restate)';
    if (isLocked) editTooltip = 'Edit Locked (Restate)';

    return [
      // Activate column: SA → activate button on draft; others → indicator or disabled
      if (isDraft && canActivate)
        _activateButton(factor, t)
      else if (isDraft && !canActivate)
        _actionIcon(
          icon: Icons.play_arrow_rounded,
          tooltip: 'Activate — Super Admin only',
          color: t.secondary,
          enabled: false,
          onTap: null,
        )
      else if (isActive)
        _activeIndicator(t)
      else
        _actionIcon(
          icon: Icons.lock_outline,
          tooltip: 'Locked',
          color: t.secondary,
          enabled: false,
          onTap: null,
        ),
      const SizedBox(width: 6),
      _actionIcon(
        icon: Icons.edit_outlined,
        tooltip: editTooltip,
        color: t.primary,
        enabled: canEdit,
        onTap: canEdit ? () => onEdit?.call(factor) : null,
      ),
      const SizedBox(width: 6),
      _actionIcon(
        icon: Icons.delete_outline,
        tooltip: canDelete ? 'Delete' : 'Delete — blocked',
        color: t.error,
        enabled: canDelete,
        onTap: canDelete ? () => onDelete?.call(factor) : null,
      ),
    ];
  }

  Widget _activateButton(EmissionFactor factor, dynamic t) {
    return _HoverActivateButton(
      onTap: () => onActivate?.call(factor),
      color: t.primary,
    );
  }

  Widget _activeIndicator(dynamic t) {
    return Tooltip(
      message: 'Currently Active',
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(Icons.play_arrow_rounded, size: 17, color: t.primary.withOpacity(0.35)),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: enabled ? tooltip : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            size: 17,
            color: enabled ? color : color.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(FactorStatus status, dynamic t, bool isLight) {
    final Color bg;
    final Color border;
    final Color text;
    final String label;
    final IconData dot;

    switch (status) {
      case FactorStatus.active:
        bg = t.success.withOpacity(0.1);
        border = t.success.withOpacity(0.35);
        text = t.success;
        label = 'ACTIVE';
        dot = Icons.circle;
        break;
      case FactorStatus.draft:
        bg = t.tertiary.withOpacity(0.1);
        border = t.tertiary.withOpacity(0.35);
        text = t.tertiary;
        label = 'DRAFT';
        dot = Icons.circle_outlined;
        break;
      case FactorStatus.locked:
        bg = t.secondaryText.withOpacity(0.06);
        border = t.secondaryText.withOpacity(0.2);
        text = t.secondaryText.withOpacity(0.6);
        label = 'LOCKED';
        dot = Icons.lock_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(dot, size: 7, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _restatedBadge(dynamic t, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: t.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.warning.withOpacity(0.3), width: 1),
      ),
      child: Text(
        'Restated',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: t.warning,
        ),
      ),
    );
  }

  Widget _sourceChip(
    String label,
    FactorStatus status,
    dynamic t,
    bool isLight,
  ) {
    final color = status == FactorStatus.active
        ? t.primary
        : status == FactorStatus.draft
            ? t.warning
            : t.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.85),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HoverActivateButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color color;

  const _HoverActivateButton({required this.onTap, required this.color});

  @override
  State<_HoverActivateButton> createState() => _HoverActivateButtonState();
}

class _HoverActivateButtonState extends State<_HoverActivateButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: 'Activate',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: _hovered ? 10 : 5, vertical: 5),
            decoration: BoxDecoration(
              color: _hovered ? widget.color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered ? widget.color.withOpacity(0.35) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 17, color: _hovered ? widget.color : widget.color.withOpacity(0.55)),
                if (_hovered) ...[
                  const SizedBox(width: 4),
                  Text(
                    'Activate',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
