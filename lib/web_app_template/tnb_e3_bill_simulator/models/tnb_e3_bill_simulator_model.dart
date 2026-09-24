import 'package:flutter/material.dart';

// ─── Breakdown Row Model ───────────────────────────────────────────────────
class TnbBreakdownItem {
  final String desc;
  final String usage;
  final String rate;
  final String amount;
  final String? tag;
  final Color? tagColor;
  final bool isPenalty;

  const TnbBreakdownItem({
    required this.desc,
    required this.usage,
    required this.rate,
    required this.amount,
    this.tag,
    this.tagColor,
    this.isPenalty = false,
  });
}

// ─── Summary Card Model ────────────────────────────────────────────────────
class TnbSummaryCardData {
  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;
  final Color? accentColor;
  final double? progressValue;
  final String? progressLabel;

  

  const TnbSummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    this.accentColor,
    this.progressValue,
    this.progressLabel,
  });
}

// ─── Header Model ──────────────────────────────────────────────────────────
class TnbHeaderData {
  final String title;
  final String subtitle;
  final String accrualLabel;
  final String accrualAmount;
   final String categoryName;

  const TnbHeaderData({
    required this.title,
    required this.subtitle,
    required this.accrualLabel,
    required this.accrualAmount,
      this.categoryName = '', 
  });
}

// ─── Main Model ────────────────────────────────────────────────────────────
class TnbE3BillSimulatorModel {
  static const String breadcrumb = 'Dashboard/TNB E3 Bill Simulator';
  static const String breakdownTitle = 'Tariff E3 Detailed Breakdown';

  static const List<TnbSummaryCardData> summaryCards = [
    TnbSummaryCardData(
      title: 'SOLAR SAVINGS (AVOIDED COST)',
      value: '- RM 42,105.00',
      subtitle: 'Generated from Lot 237 & S3',
      valueColor: Color(0xFF00C853),
    ),
    TnbSummaryCardData(
      title: 'PF SURCHARGE RISK',
      value: '0.82 PF',
      subtitle: '',
      valueColor: Color(0xFFE53935),
      accentColor: Color(0xFFE53935),
      progressValue: 0.82,
      progressLabel: 'Requires Action: Check Capacitor Banks',
    ),
    TnbSummaryCardData(
      title: 'EST. BILLING CYCLE END',
      value: '12 Days Left',
      subtitle: 'Cycle: 1st - 31st March',
      valueColor: Colors.white,
    ),
  ];

  static const String footerNote =
      '*This is a real-time simulation based on TNB E3 High Voltage tariff structures. Official bills may vary by < 1%.  ';
  static const String footerSource = 'Data Source: DELAB PQM1000 Master Meter';
}