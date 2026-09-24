import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeRangeFilterDialog extends StatefulWidget {
  final List<Map<String, dynamic>> utilizationData;
  final String? machineId;
  final String? workOrderId;
  final String? processID;
  final int initialRunning;
  final int initialIdle;
  final int initialStopped;

  const TimeRangeFilterDialog({
    super.key,
    required this.utilizationData,
    this.machineId,
    this.workOrderId,
    this.processID,
    this.initialRunning = 0,
    this.initialIdle = 0,
    this.initialStopped = 0,
  });

  @override
  State<TimeRangeFilterDialog> createState() => _TimeRangeFilterDialogState();
}

class _TimeRangeFilterDialogState extends State<TimeRangeFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int _filteredRunning = 0;
  int _filteredIdle = 0;
  int _filteredStopped = 0;
  bool _isFiltered = false;
  List<Map<String, dynamic>> _currentFilteredData = [];

  // Define colors for each status
  final Color idleColor = const Color(0xFFFBBF24); // Yellow
  final Color runningColor = const Color(0xFF22C55E); // Green
  final Color stoppedColor = const Color(0xFFEF4444); // Red

  @override
  void initState() {
    super.initState();
    _filteredRunning = widget.initialRunning;
    _filteredIdle = widget.initialIdle;
    _filteredStopped = widget.initialStopped;
  }

  void _calculateTotals(List<Map<String, dynamic>> data) {
    int running = 0;
    int idle = 0;
    int stopped = 0;

    for (var record in data) {
      // Try runStatus first (which is used in the progress bar)
      int? status = record['runStatus'] as int?;

      // Fallback to machine_status if runStatus is not available
      if (status == null) {
        final statusStr = record['machine_status']?.toString() ?? '';
        if (statusStr.isNotEmpty) {
          status = int.tryParse(statusStr);
        }
      }

      // Each record represents 1 minute in the timeline
      if (status != null) {
        switch (status) {
          case 1: // Running
            running++;
            break;
          case 2: // Idle
            idle++;
            break;
          case 3: // Stopped
            stopped++;
            break;
          case 0: // Also check for 0 as idle (alternative format)
            idle++;
            break;
        }
      }
    }

    setState(() {
      _filteredRunning = running;
      _filteredIdle = idle;
      _filteredStopped = stopped;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlutterFlowTheme.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _selectStartTime();
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlutterFlowTheme.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlutterFlowTheme.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _selectEndTime();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlutterFlowTheme.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _applyFilter() {
    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both start and end date/time')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (startDateTime.isAfter(endDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Start date/time must be before end date/time')),
      );
      return;
    }

    // Filter data based on time range
    final filteredData = widget.utilizationData.where((record) {
      final timestampStr = record['timestamp']?.toString();
      if (timestampStr == null) return false;

      try {
        final timestamp = DateTime.parse(timestampStr);
        return timestamp.isAfter(startDateTime) &&
            timestamp.isBefore(endDateTime);
      } catch (e) {
        return false;
      }
    }).toList();

    _calculateTotals(filteredData);
    setState(() {
      _isFiltered = true;
      _currentFilteredData = filteredData;
    });

    // Close dialog and return filtered data including the utilization data
    Navigator.pop(context, {
      'running': _filteredRunning,
      'idle': _filteredIdle,
      'stopped': _filteredStopped,
      'isFiltered': true,
      'filterInfo':
          '${_formatDateTime(_startDate, _startTime)} - ${_formatDateTime(_endDate, _endTime)}',
      'filteredData':
          filteredData, // Include the actual filtered utilization data
    });
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _startTime = null;
      _endTime = null;
      _isFiltered = false;
      _filteredRunning = widget.initialRunning;
      _filteredIdle = widget.initialIdle;
      _filteredStopped = widget.initialStopped;
      _currentFilteredData = [];
    });
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'Not selected';
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final formattedTime = time.format(context);
    return '$formattedDate $formattedTime';
  }

  Widget _buildStatCard(String label, int minutes, Color color) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    final total = _filteredRunning + _filteredIdle + _filteredStopped;
    final percentage = total > 0 ? (minutes / total * 100) : 0.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FlutterFlowTheme.of(context).txtSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${hours}h ${mins}m',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: FlutterFlowTheme.of(context).txtTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _filteredRunning + _filteredIdle + _filteredStopped;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Machine Utilization Details',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.machineId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Machine: ${widget.machineId}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Machine Info
                    if (widget.workOrderId != null ||
                        widget.processID != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: FlutterFlowTheme.of(context).primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.workOrderId != null)
                                    _buildInfoRow(
                                        'Work Order ID', widget.workOrderId!),
                                  if (widget.processID != null) ...[
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                        'Operation ID', widget.processID!),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Stats Cards
                    Row(
                      children: [
                        _buildStatCard(
                            'Running', _filteredRunning, runningColor),
                        const SizedBox(width: 12),
                        _buildStatCard('Idle', _filteredIdle, idleColor),
                        const SizedBox(width: 12),
                        _buildStatCard(
                            'Stopped', _filteredStopped, stoppedColor),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Total Time
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Time',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: FlutterFlowTheme.of(context).txtPrimary,
                            ),
                          ),
                          Text(
                            '${total ~/ 60}h ${total % 60}m',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 24),

                    // Time Range Selection
                    Text(
                      'Time Range Filter',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date/Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            'Start Date & Time',
                            _formatDateTime(_startDate, _startTime),
                            _selectStartDate,
                            Icons.calendar_today,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // End Date/Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            'End Date & Time',
                            _formatDateTime(_endDate, _endTime),
                            _selectEndDate,
                            Icons.event,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Filter Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _applyFilter,
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Apply Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetFilter,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              side: BorderSide(
                                  color: FlutterFlowTheme.of(context).primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_isFiltered) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).iconSoftBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: FlutterFlowTheme.of(context).primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Filter applied: Showing data from ${_formatDateTime(_startDate, _startTime)} to ${_formatDateTime(_endDate, _endTime)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: FlutterFlowTheme.of(context).txtTertiary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: FlutterFlowTheme.of(context).txtPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeButton(
      String label, String value, VoidCallback onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: FlutterFlowTheme.of(context).cardStroke),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: FlutterFlowTheme.of(context).primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: FlutterFlowTheme.of(context).txtTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: FlutterFlowTheme.of(context).txtMuted),
          ],
        ),
      ),
    );
  }
}
