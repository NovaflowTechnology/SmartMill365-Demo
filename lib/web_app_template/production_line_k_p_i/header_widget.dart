import 'package:flutter/material.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class HeaderWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onApply;
  final String lastUpdateTime;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime, DateTime)? onDateRangeChanged;

  const HeaderWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    this.onApply,
    required this.lastUpdateTime,
    this.initialStartDate,
    this.initialEndDate,
    this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<HeaderWidget> createState() => _DashboardHeaderWidgetState();
}

class _DashboardHeaderWidgetState extends State<HeaderWidget> {
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use initial values from parent or set defaults to last 7 days
    final now = DateTime.now();
    startDate = widget.initialStartDate ?? DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    endDate = widget.initialEndDate ?? DateTime(now.year, now.month, now.day);

    _updateDateControllers();
  }

  @override
  void didUpdateWidget(HeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update dates if parent changed them
    if (widget.initialStartDate != oldWidget.initialStartDate || widget.initialEndDate != oldWidget.initialEndDate) {
      setState(() {
        startDate = widget.initialStartDate;
        endDate = widget.initialEndDate;
        _updateDateControllers();
      });
    }
  }

  void _updateDateControllers() {
    if (startDate != null) {
      startDateController.text = '${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}';
    }
    if (endDate != null) {
      endDateController.text = '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}';
    }
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final theme = FlutterFlowTheme.of(context);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.primary,
              onPrimary: theme.primaryText,
              surface: theme.secondaryBackground,
              onSurface: theme.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        startDateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      // Notify parent of date change
      if (endDate != null) {
        widget.onDateRangeChanged?.call(picked, endDate!);
      }
    }
  }

  Future<void> _selectEndDate() async {
    final theme = FlutterFlowTheme.of(context);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.primary,
              onPrimary: theme.primaryText,
              surface: theme.secondaryBackground,
              onSurface: theme.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        endDateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      // Notify parent of date change
      if (startDate != null) {
        widget.onDateRangeChanged?.call(startDate!, picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Left side - Title and Subtitle
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.headlineMedium.override(
                      fontFamily: 'Poppins',
                      color: theme.primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      font: theme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: theme.bodyLarge.override(
                      fontFamily: 'Poppins',
                      color: theme.primaryText.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      font: theme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),

            // Right side - Date Range Picker and Apply Button
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // First Row: Last Updated info and Date Filters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Last Update Time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.update, size: 20, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Last Updated',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.lastUpdateTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Date filter controls
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Calendar Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryText.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.calendar_month,
                                color: theme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Start Date Field
                            Flexible(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.alternate.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: startDateController,
                                  readOnly: true,
                                  onTap: _selectStartDate,
                                  style: theme.bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    color: theme.primaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    font: theme.bodyMedium,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.secondaryText,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'to',
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Poppins',
                                  color: theme.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  font: theme.bodyMedium,
                                ),
                              ),
                            ),

                            // End Date Field
                            Flexible(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.alternate.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: endDateController,
                                  readOnly: true,
                                  onTap: _selectEndDate,
                                  style: theme.bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    color: theme.primaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    font: theme.bodyMedium,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.secondaryText,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Second Row: Apply Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primary,
                              theme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onApply,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: theme.primaryBackground,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Apply',
                                    style: theme.labelLarge.override(
                                      fontFamily: 'Poppins',
                                      color: theme.primaryBackground,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      font: theme.labelLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
