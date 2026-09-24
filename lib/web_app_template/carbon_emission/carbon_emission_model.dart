import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'carbon_emission_widget.dart' show CarbonEmissionWidget;

// ── Enums ─────────────────────────────────────────────────────────────────────

enum DeviceStatus { live, idle, offline, stale }

enum DeviceCategory {
  stretchFilmLine,
  castFilmLine,
  blownFilmLine,
  utilitiesOthers,
  solarGeneration,
}

// ── Data Models ───────────────────────────────────────────────────────────────

class DeviceEmissionRow {
  final String id;
  final String name;
  final String subtitle;
  final DeviceStatus status;
  final DeviceCategory category;
  final bool isSolar;

  // Live layer
  final double? liveKw;
  final double? liveCo2Rate; // tCO₂e/hr

  // Daily layer
  final double? dailyKwh;
  final double? dailyTco2e;

  // Monthly layer
  final double? kwhMonthly;
  final double? tco2eMonthly;
  final double? sharePercent;

  // Site-to-date layer
  final double? siteKwh;
  final double? siteTco2e;

  // Intensity (kgCO₂e/tonne·product)
  final double? intensity;

  const DeviceEmissionRow({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.category,
    this.isSolar = false,
    this.liveKw,
    this.liveCo2Rate,
    this.dailyKwh,
    this.dailyTco2e,
    this.kwhMonthly,
    this.tco2eMonthly,
    this.sharePercent,
    this.siteKwh,
    this.siteTco2e,
    this.intensity,
  });
}

class MonthlyTrendPoint {
  final String month;
  final double grossTco2e;
  final double solarAvoided;

  const MonthlyTrendPoint({
    required this.month,
    required this.grossTco2e,
    required this.solarAvoided,
  });
}

class DeviceHourlyPoint {
  final String label;
  final double kwh;
  const DeviceHourlyPoint({required this.label, required this.kwh});
}

class BursaReportRow {
  final String month;
  final double scope1;
  final double scope2Gross;
  final double solarAvoided;

  const BursaReportRow({
    required this.month,
    required this.scope1,
    required this.scope2Gross,
    required this.solarAvoided,
  });

  double get scope2Net => scope2Gross - solarAvoided;
  double get totalNet => scope1 + scope2Net;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final kMockDeviceEmissions = <DeviceEmissionRow>[
  // ── Stretch Film Lines ──────────────────────────────────────────────────────
  const DeviceEmissionRow(
    id: 'td9',
    name: 'TD9',
    subtitle: 'Stretch Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.stretchFilmLine,
    liveKw: 107.8,
    liveCo2Rate: 0.0619,
    dailyKwh: 64200,
    dailyTco2e: 36.8508,
    kwhMonthly: 1910000,
    tco2eMonthly: 1096.340,
    sharePercent: 32.1,
    siteKwh: 9620000,
    siteTco2e: 5521.880,
    intensity: 41.9,
  ),
  const DeviceEmissionRow(
    id: 'td7',
    name: 'TD7',
    subtitle: 'Stretch Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.stretchFilmLine,
    liveKw: 91.3,
    liveCo2Rate: 0.0524,
    dailyKwh: 49800,
    dailyTco2e: 28.5852,
    kwhMonthly: 1540000,
    tco2eMonthly: 883.960,
    sharePercent: 26.9,
    siteKwh: 7890000,
    siteTco2e: 4528.860,
    intensity: 38.2,
  ),
  const DeviceEmissionRow(
    id: 'td8',
    name: 'TD8',
    subtitle: 'Stretch Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.stretchFilmLine,
    liveKw: 88.1,
    liveCo2Rate: 0.0506,
    dailyKwh: 31200,
    dailyTco2e: 17.9088,
    kwhMonthly: 1460000,
    tco2eMonthly: 838.040,
    sharePercent: 24.7,
    siteKwh: 8140000,
    siteTco2e: 4672.360,
    intensity: 40.1,
  ),
  const DeviceEmissionRow(
    id: 'td10',
    name: 'TD10',
    subtitle: 'Stretch Film Line',
    status: DeviceStatus.idle,
    category: DeviceCategory.stretchFilmLine,
    liveKw: 0.0,
    liveCo2Rate: 0.0,
    dailyKwh: 0,
    dailyTco2e: 0.0,
    kwhMonthly: 312000,
    tco2eMonthly: 179.088,
    sharePercent: null,
    siteKwh: 820000,
    siteTco2e: 470.680,
  ),

  // ── Cast Film Lines ─────────────────────────────────────────────────────────
  const DeviceEmissionRow(
    id: 'cm1',
    name: 'CM1',
    subtitle: 'Cast Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.castFilmLine,
    liveKw: 41.4,
    liveCo2Rate: 0.0238,
    dailyKwh: 52300,
    dailyTco2e: 30.0202,
    kwhMonthly: 576000,
    tco2eMonthly: 330.624,
    sharePercent: 9.7,
    siteKwh: 2940000,
    siteTco2e: 1687.560,
    intensity: 36.8,
  ),
  const DeviceEmissionRow(
    id: 'cm2',
    name: 'CM2',
    subtitle: 'Cast Film Line',
    status: DeviceStatus.idle,
    category: DeviceCategory.castFilmLine,
    liveKw: 0.0,
    liveCo2Rate: 0.0,
    dailyKwh: 0,
    dailyTco2e: 0.0,
    kwhMonthly: 88400,
    tco2eMonthly: 50.742,
    siteKwh: 410000,
    siteTco2e: 235.340,
  ),

  // ── Blown Film Lines ────────────────────────────────────────────────────────
  const DeviceEmissionRow(
    id: 'c7',
    name: 'C7',
    subtitle: 'Blown Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.blownFilmLine,
    liveKw: 0.4,
    liveCo2Rate: 0.0002,
    dailyKwh: 952,
    dailyTco2e: 0.5464,
    kwhMonthly: 28600,
    tco2eMonthly: 16.416,
    sharePercent: 0.5,
    siteKwh: 144000,
    siteTco2e: 82.656,
    intensity: 45.2,
  ),
  const DeviceEmissionRow(
    id: 'c8',
    name: 'C8',
    subtitle: 'Blown Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.blownFilmLine,
    liveKw: 0.3,
    liveCo2Rate: 0.0002,
    dailyKwh: 0,
    dailyTco2e: 0.0,
    kwhMonthly: 22100,
    tco2eMonthly: 12.685,
    sharePercent: 0.4,
    siteKwh: 112000,
    siteTco2e: 64.288,
    intensity: 43.8,
  ),
  const DeviceEmissionRow(
    id: 'c9',
    name: 'C9',
    subtitle: 'Blown Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.blownFilmLine,
    liveKw: 0.6,
    liveCo2Rate: 0.0003,
    dailyKwh: 407,
    dailyTco2e: 0.2336,
    kwhMonthly: 12200,
    tco2eMonthly: 7.003,
    sharePercent: 1.2,
    siteKwh: 61800,
    siteTco2e: 35.473,
    intensity: 47.1,
  ),
  const DeviceEmissionRow(
    id: 'c2',
    name: 'C2',
    subtitle: 'Blown Film Line',
    status: DeviceStatus.live,
    category: DeviceCategory.blownFilmLine,
    liveKw: 0.2,
    liveCo2Rate: 0.0001,
    dailyKwh: 483,
    dailyTco2e: 0.2772,
    kwhMonthly: 14500,
    tco2eMonthly: 8.323,
    sharePercent: 0.2,
    siteKwh: 73400,
    siteTco2e: 42.132,
    intensity: 46.3,
  ),

  // ── Utilities & Others ──────────────────────────────────────────────────────
  const DeviceEmissionRow(
    id: 'td9sub',
    name: 'TD9_SUB',
    subtitle: 'Sub Distribution',
    status: DeviceStatus.live,
    category: DeviceCategory.utilitiesOthers,
    liveKw: 9.0,
    liveCo2Rate: 0.0052,
    dailyKwh: 11400,
    dailyTco2e: 6.5436,
    kwhMonthly: 342000,
    tco2eMonthly: 196.308,
    sharePercent: 5.8,
    siteKwh: 1740000,
    siteTco2e: 998.760,
  ),
  const DeviceEmissionRow(
    id: 'c10',
    name: 'C10',
    subtitle: 'Compressor',
    status: DeviceStatus.live,
    category: DeviceCategory.utilitiesOthers,
    liveKw: 0.0,
    liveCo2Rate: 0.0,
    dailyKwh: 577,
    dailyTco2e: 0.3312,
    kwhMonthly: 17300,
    tco2eMonthly: 9.938,
    sharePercent: 0.3,
    siteKwh: 87500,
    siteTco2e: 50.225,
  ),
  const DeviceEmissionRow(
    id: 'motan',
    name: 'MOTAN',
    subtitle: 'Material Handling',
    status: DeviceStatus.offline,
    category: DeviceCategory.utilitiesOthers,
  ),
  const DeviceEmissionRow(
    id: 'ca',
    name: 'CA',
    subtitle: 'Compressed Air',
    status: DeviceStatus.stale,
    category: DeviceCategory.utilitiesOthers,
    liveKw: 0.0,
    liveCo2Rate: 0.0,
    dailyKwh: 0,
    dailyTco2e: 0.0,
    kwhMonthly: 0,
    tco2eMonthly: 0.0,
    siteKwh: 0,
    siteTco2e: 0.0,
  ),
  const DeviceEmissionRow(
    id: 'msb',
    name: 'MSB',
    subtitle: 'Main Supply Bus',
    status: DeviceStatus.live,
    category: DeviceCategory.utilitiesOthers,
    liveKw: 314.0,
    liveCo2Rate: 0.1802,
    dailyKwh: 0,
    dailyTco2e: 0.0,
    kwhMonthly: 0,
    tco2eMonthly: 0.0,
    siteKwh: 0,
    siteTco2e: 0.0,
  ),

  // ── Solar Generation ────────────────────────────────────────────────────────
  const DeviceEmissionRow(
    id: 'solar_pv',
    name: 'Solar PV',
    subtitle: 'On-site PV Generation',
    status: DeviceStatus.live,
    category: DeviceCategory.solarGeneration,
    isSolar: true,
    liveKw: 28.4,
    liveCo2Rate: -0.0163,
    dailyKwh: 1400,
    dailyTco2e: -0.8053,
    kwhMonthly: 42100,
    tco2eMonthly: -24.168,
    siteKwh: 238500,
    siteTco2e: -120.841,
  ),
];

// ── Per-tab KPI data ──────────────────────────────────────────────────────────

class CarbonKpiData {
  const CarbonKpiData({
    required this.grossTco2e,
    required this.solarAvoided,
    required this.netTco2e,
    required this.intensity,
    required this.grossTrend,
    required this.grossTrendUp,
    required this.solarTrend,
    required this.solarTrendUp,
    required this.netTrend,
    required this.netTrendUp,
    required this.intensityTrend,
    required this.intensityTrendUp,
    required this.grossFormula,
    required this.solarFormula,
  });
  final double grossTco2e;
  final double solarAvoided;
  final double netTco2e;
  final double intensity;
  final String grossTrend;
  final bool grossTrendUp;
  final String solarTrend;
  final bool solarTrendUp;
  final String netTrend;
  final bool netTrendUp;
  final String intensityTrend;
  final bool intensityTrendUp;
  final String grossFormula;
  final String solarFormula;
}

// index 0=Live, 1=Daily, 2=Monthly, 3=YTD
const kTabKpiData = [
  // Live — current month running total
  CarbonKpiData(
    grossTco2e: 1395.9, solarAvoided: 24.2, netTco2e: 1371.7, intensity: 23.7,
    grossTrend: '+3.2% vs last month', grossTrendUp: true,
    solarTrend: '-1.4% solar generation', solarTrendUp: false,
    netTrend: '+3.8% vs last month', netTrendUp: true,
    intensityTrend: '-0.8% efficiency gain', intensityTrendUp: false,
    grossFormula: '2,431,880 kWh (month) × 0.574 × 1000',
    solarFormula: '42,105 kWh solar × 0.574 × 1000',
  ),
  // Daily — 08 May 2025
  CarbonKpiData(
    grossTco2e: 52.3, solarAvoided: 0.8, netTco2e: 51.5, intensity: 23.5,
    grossTrend: '+1.8% vs yesterday', grossTrendUp: true,
    solarTrend: '+5.2% vs yesterday', solarTrendUp: true,
    netTrend: '+1.6% vs yesterday', netTrendUp: true,
    intensityTrend: '-0.3% vs yesterday', intensityTrendUp: false,
    grossFormula: '91,102 kWh (today) × 0.574 × 1000',
    solarFormula: '1,394 kWh solar × 0.574 × 1000',
  ),
  // Monthly — May 2025 MTD
  CarbonKpiData(
    grossTco2e: 1395.9, solarAvoided: 24.2, netTco2e: 1371.7, intensity: 23.7,
    grossTrend: '+3.2% vs Apr 2025', grossTrendUp: true,
    solarTrend: '-1.4% solar generation', solarTrendUp: false,
    netTrend: '+3.4% vs Apr 2025', netTrendUp: true,
    intensityTrend: '-0.8% efficiency gain', intensityTrendUp: false,
    grossFormula: '2,431,880 kWh (May MTD) × 0.574 × 1000',
    solarFormula: '42,105 kWh solar × 0.574 × 1000',
  ),
  // YTD — FY2025 Jan–May
  CarbonKpiData(
    grossTco2e: 8374.9, solarAvoided: 120.8, netTco2e: 8254.1, intensity: 23.7,
    grossTrend: '+0.1% vs FY2024 YTD', grossTrendUp: true,
    solarTrend: '+17.2% vs FY2024 YTD', solarTrendUp: true,
    netTrend: '-0.2% vs FY2024 YTD', netTrendUp: false,
    intensityTrend: '-0.8% vs FY2024 YTD', intensityTrendUp: false,
    grossFormula: '14,590,860 kWh (Jan–May) × 0.574 × 1000',
    solarFormula: '210,525 kWh solar × 0.574 × 1000',
  ),
];

// ── Daily device data (08 May) ────────────────────────────────────────────────

final kMockDeviceEmissionsDaily = <DeviceEmissionRow>[
  const DeviceEmissionRow(id: 'td9', name: 'TD9', subtitle: 'Stretch Film Line',
    status: DeviceStatus.live, category: DeviceCategory.stretchFilmLine,
    liveKw: 107.8, liveCo2Rate: 0.0619,
    kwhMonthly: 64200, tco2eMonthly: 36.851, sharePercent: 33.1, intensity: 41.9,
    siteKwh: 64200, siteTco2e: 36.851),
  const DeviceEmissionRow(id: 'td7', name: 'TD7', subtitle: 'Stretch Film Line',
    status: DeviceStatus.live, category: DeviceCategory.stretchFilmLine,
    liveKw: 91.3, liveCo2Rate: 0.0524,
    kwhMonthly: 49800, tco2eMonthly: 28.585, sharePercent: 25.7, intensity: 38.2,
    siteKwh: 49800, siteTco2e: 28.585),
  const DeviceEmissionRow(id: 'td8', name: 'TD8', subtitle: 'Stretch Film Line',
    status: DeviceStatus.live, category: DeviceCategory.stretchFilmLine,
    liveKw: 88.1, liveCo2Rate: 0.0506,
    kwhMonthly: 31200, tco2eMonthly: 17.909, sharePercent: 16.4, intensity: 40.1,
    siteKwh: 31200, siteTco2e: 17.909),
  const DeviceEmissionRow(id: 'td10', name: 'TD10', subtitle: 'Stretch Film Line',
    status: DeviceStatus.idle, category: DeviceCategory.stretchFilmLine,
    liveKw: 0.0, liveCo2Rate: 0.0, kwhMonthly: 0, tco2eMonthly: 0.0,
    siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'cm1', name: 'CM1', subtitle: 'Cast Film Line',
    status: DeviceStatus.live, category: DeviceCategory.castFilmLine,
    liveKw: 41.4, liveCo2Rate: 0.0238,
    kwhMonthly: 52300, tco2eMonthly: 30.020, sharePercent: 27.0, intensity: 36.8,
    siteKwh: 52300, siteTco2e: 30.020),
  const DeviceEmissionRow(id: 'cm2', name: 'CM2', subtitle: 'Cast Film Line',
    status: DeviceStatus.idle, category: DeviceCategory.castFilmLine,
    liveKw: 0.0, liveCo2Rate: 0.0, kwhMonthly: 0, tco2eMonthly: 0.0,
    siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'c7', name: 'C7', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.4, liveCo2Rate: 0.0002,
    kwhMonthly: 952, tco2eMonthly: 0.546, sharePercent: 0.5, intensity: 45.2,
    siteKwh: 952, siteTco2e: 0.546),
  const DeviceEmissionRow(id: 'c8', name: 'C8', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.3, liveCo2Rate: 0.0002,
    kwhMonthly: 0, tco2eMonthly: 0.0, siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'c9', name: 'C9', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.6, liveCo2Rate: 0.0003,
    kwhMonthly: 407, tco2eMonthly: 0.234, sharePercent: 0.2, intensity: 47.1,
    siteKwh: 407, siteTco2e: 0.234),
  const DeviceEmissionRow(id: 'c2', name: 'C2', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.2, liveCo2Rate: 0.0001,
    kwhMonthly: 483, tco2eMonthly: 0.277, sharePercent: 0.3, intensity: 46.3,
    siteKwh: 483, siteTco2e: 0.277),
  const DeviceEmissionRow(id: 'td9sub', name: 'TD9_SUB', subtitle: 'Sub Distribution',
    status: DeviceStatus.live, category: DeviceCategory.utilitiesOthers,
    liveKw: 9.0, liveCo2Rate: 0.0052,
    kwhMonthly: 11400, tco2eMonthly: 6.544, sharePercent: 5.9,
    siteKwh: 11400, siteTco2e: 6.544),
  const DeviceEmissionRow(id: 'c10', name: 'C10', subtitle: 'Compressor',
    status: DeviceStatus.live, category: DeviceCategory.utilitiesOthers,
    liveKw: 0.0, liveCo2Rate: 0.0,
    kwhMonthly: 577, tco2eMonthly: 0.331, sharePercent: 0.3,
    siteKwh: 577, siteTco2e: 0.331),
  const DeviceEmissionRow(id: 'motan', name: 'MOTAN', subtitle: 'Material Handling',
    status: DeviceStatus.offline, category: DeviceCategory.utilitiesOthers),
  const DeviceEmissionRow(id: 'ca', name: 'CA', subtitle: 'Compressed Air',
    status: DeviceStatus.stale, category: DeviceCategory.utilitiesOthers,
    liveKw: 0.0, liveCo2Rate: 0.0, kwhMonthly: 0, tco2eMonthly: 0.0,
    siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'msb', name: 'MSB', subtitle: 'Main Supply Bus',
    status: DeviceStatus.live, category: DeviceCategory.utilitiesOthers,
    liveKw: 314.0, liveCo2Rate: 0.1802,
    kwhMonthly: 0, tco2eMonthly: 0.0, siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'solar_pv', name: 'Solar PV', subtitle: 'On-site PV Generation',
    status: DeviceStatus.live, category: DeviceCategory.solarGeneration, isSolar: true,
    liveKw: 28.4, liveCo2Rate: -0.0163,
    kwhMonthly: 1400, tco2eMonthly: -0.805, siteKwh: 1400, siteTco2e: -0.805),
];

// ── YTD device data (Jan–May FY2025) ─────────────────────────────────────────

final kMockDeviceEmissionsYtd = <DeviceEmissionRow>[
  const DeviceEmissionRow(id: 'td9', name: 'TD9', subtitle: 'Stretch Film Line',
    status: DeviceStatus.live, category: DeviceCategory.stretchFilmLine,
    liveKw: 107.8, liveCo2Rate: 0.0619,
    kwhMonthly: 9620000, tco2eMonthly: 5521.880, sharePercent: 32.4, intensity: 41.9,
    siteKwh: 9620000, siteTco2e: 5521.880),
  const DeviceEmissionRow(id: 'td7', name: 'TD7', subtitle: 'Stretch Film Line',
    status: DeviceStatus.live, category: DeviceCategory.stretchFilmLine,
    liveKw: 91.3, liveCo2Rate: 0.0524,
    kwhMonthly: 7890000, tco2eMonthly: 4528.860, sharePercent: 26.6, intensity: 38.2,
    siteKwh: 7890000, siteTco2e: 4528.860),
  const DeviceEmissionRow(id: 'td8', name: 'TD8', subtitle: 'Stretch Film Line',
    status: DeviceStatus.live, category: DeviceCategory.stretchFilmLine,
    liveKw: 88.1, liveCo2Rate: 0.0506,
    kwhMonthly: 8140000, tco2eMonthly: 4672.360, sharePercent: 27.4, intensity: 40.1,
    siteKwh: 8140000, siteTco2e: 4672.360),
  const DeviceEmissionRow(id: 'td10', name: 'TD10', subtitle: 'Stretch Film Line',
    status: DeviceStatus.idle, category: DeviceCategory.stretchFilmLine,
    liveKw: 0.0, liveCo2Rate: 0.0,
    kwhMonthly: 820000, tco2eMonthly: 470.680, siteKwh: 820000, siteTco2e: 470.680),
  const DeviceEmissionRow(id: 'cm1', name: 'CM1', subtitle: 'Cast Film Line',
    status: DeviceStatus.live, category: DeviceCategory.castFilmLine,
    liveKw: 41.4, liveCo2Rate: 0.0238,
    kwhMonthly: 2940000, tco2eMonthly: 1687.560, sharePercent: 9.9, intensity: 36.8,
    siteKwh: 2940000, siteTco2e: 1687.560),
  const DeviceEmissionRow(id: 'cm2', name: 'CM2', subtitle: 'Cast Film Line',
    status: DeviceStatus.idle, category: DeviceCategory.castFilmLine,
    liveKw: 0.0, liveCo2Rate: 0.0,
    kwhMonthly: 410000, tco2eMonthly: 235.340, siteKwh: 410000, siteTco2e: 235.340),
  const DeviceEmissionRow(id: 'c7', name: 'C7', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.4, liveCo2Rate: 0.0002,
    kwhMonthly: 144000, tco2eMonthly: 82.656, sharePercent: 0.5, intensity: 45.2,
    siteKwh: 144000, siteTco2e: 82.656),
  const DeviceEmissionRow(id: 'c8', name: 'C8', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.3, liveCo2Rate: 0.0002,
    kwhMonthly: 112000, tco2eMonthly: 64.288, sharePercent: 0.4, intensity: 43.8,
    siteKwh: 112000, siteTco2e: 64.288),
  const DeviceEmissionRow(id: 'c9', name: 'C9', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.6, liveCo2Rate: 0.0003,
    kwhMonthly: 61800, tco2eMonthly: 35.473, sharePercent: 0.4, intensity: 47.1,
    siteKwh: 61800, siteTco2e: 35.473),
  const DeviceEmissionRow(id: 'c2', name: 'C2', subtitle: 'Blown Film Line',
    status: DeviceStatus.live, category: DeviceCategory.blownFilmLine,
    liveKw: 0.2, liveCo2Rate: 0.0001,
    kwhMonthly: 73400, tco2eMonthly: 42.132, sharePercent: 0.2, intensity: 46.3,
    siteKwh: 73400, siteTco2e: 42.132),
  const DeviceEmissionRow(id: 'td9sub', name: 'TD9_SUB', subtitle: 'Sub Distribution',
    status: DeviceStatus.live, category: DeviceCategory.utilitiesOthers,
    liveKw: 9.0, liveCo2Rate: 0.0052,
    kwhMonthly: 1740000, tco2eMonthly: 998.760, sharePercent: 5.9,
    siteKwh: 1740000, siteTco2e: 998.760),
  const DeviceEmissionRow(id: 'c10', name: 'C10', subtitle: 'Compressor',
    status: DeviceStatus.live, category: DeviceCategory.utilitiesOthers,
    liveKw: 0.0, liveCo2Rate: 0.0,
    kwhMonthly: 87500, tco2eMonthly: 50.225, sharePercent: 0.3,
    siteKwh: 87500, siteTco2e: 50.225),
  const DeviceEmissionRow(id: 'motan', name: 'MOTAN', subtitle: 'Material Handling',
    status: DeviceStatus.offline, category: DeviceCategory.utilitiesOthers),
  const DeviceEmissionRow(id: 'ca', name: 'CA', subtitle: 'Compressed Air',
    status: DeviceStatus.stale, category: DeviceCategory.utilitiesOthers,
    liveKw: 0.0, liveCo2Rate: 0.0, kwhMonthly: 0, tco2eMonthly: 0.0,
    siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'msb', name: 'MSB', subtitle: 'Main Supply Bus',
    status: DeviceStatus.live, category: DeviceCategory.utilitiesOthers,
    liveKw: 314.0, liveCo2Rate: 0.1802,
    kwhMonthly: 0, tco2eMonthly: 0.0, siteKwh: 0, siteTco2e: 0.0),
  const DeviceEmissionRow(id: 'solar_pv', name: 'Solar PV', subtitle: 'On-site PV Generation',
    status: DeviceStatus.live, category: DeviceCategory.solarGeneration, isSolar: true,
    liveKw: 28.4, liveCo2Rate: -0.0163,
    kwhMonthly: 238500, tco2eMonthly: -120.841, siteKwh: 238500, siteTco2e: -120.841),
];

// ── Monthly trend per tab ─────────────────────────────────────────────────────

const kTrendDaily = [
  MonthlyTrendPoint(month: 'W1', grossTco2e: 48.2, solarAvoided: 0.7),
  MonthlyTrendPoint(month: 'W2', grossTco2e: 51.6, solarAvoided: 0.8),
  MonthlyTrendPoint(month: 'W3', grossTco2e: 49.8, solarAvoided: 0.7),
  MonthlyTrendPoint(month: 'W4', grossTco2e: 53.1, solarAvoided: 0.9),
  MonthlyTrendPoint(month: 'W5', grossTco2e: 50.4, solarAvoided: 0.8),
  MonthlyTrendPoint(month: 'W6', grossTco2e: 52.3, solarAvoided: 0.8),
];

const kTrendYtd = [
  MonthlyTrendPoint(month: 'Jan', grossTco2e: 1312.4, solarAvoided: 17.8),
  MonthlyTrendPoint(month: 'Feb', grossTco2e: 1198.6, solarAvoided: 16.4),
  MonthlyTrendPoint(month: 'Mar', grossTco2e: 1345.2, solarAvoided: 19.1),
  MonthlyTrendPoint(month: 'Apr', grossTco2e: 1289.8, solarAvoided: 20.5),
  MonthlyTrendPoint(month: 'May', grossTco2e: 1395.9, solarAvoided: 22.3),
  MonthlyTrendPoint(month: 'Jun', grossTco2e: 0.0, solarAvoided: 0.0),
];

final kMockMonthlyTrend = <MonthlyTrendPoint>[
  const MonthlyTrendPoint(month: 'Jul', grossTco2e: 1312.4, solarAvoided: 19.2),
  const MonthlyTrendPoint(month: 'Aug', grossTco2e: 1356.8, solarAvoided: 21.4),
  const MonthlyTrendPoint(month: 'Sep', grossTco2e: 1289.5, solarAvoided: 22.1),
  const MonthlyTrendPoint(month: 'Oct', grossTco2e: 1378.2, solarAvoided: 23.0),
  const MonthlyTrendPoint(month: 'Nov', grossTco2e: 1341.6, solarAvoided: 22.8),
  const MonthlyTrendPoint(month: 'Dec', grossTco2e: 1395.9, solarAvoided: 24.2),
];

final kMockBursaReport = <BursaReportRow>[
  const BursaReportRow(month: 'Jan 2025', scope1: 0.00, scope2Gross: 1312.4, solarAvoided: 17.8),
  const BursaReportRow(month: 'Feb 2025', scope1: 0.00, scope2Gross: 1198.6, solarAvoided: 16.4),
  const BursaReportRow(month: 'Mar 2025', scope1: 0.00, scope2Gross: 1345.2, solarAvoided: 19.1),
  const BursaReportRow(month: 'Apr 2025', scope1: 0.00, scope2Gross: 1289.8, solarAvoided: 20.5),
  const BursaReportRow(month: 'May 2025', scope1: 0.00, scope2Gross: 1356.4, solarAvoided: 22.3),
  const BursaReportRow(month: 'Jun 2025', scope1: 0.00, scope2Gross: 1402.1, solarAvoided: 23.6),
  const BursaReportRow(month: 'Jul 2025', scope1: 0.00, scope2Gross: 1312.4, solarAvoided: 19.2),
  const BursaReportRow(month: 'Aug 2025', scope1: 0.00, scope2Gross: 1356.8, solarAvoided: 21.4),
  const BursaReportRow(month: 'Sep 2025', scope1: 0.00, scope2Gross: 1289.5, solarAvoided: 22.1),
  const BursaReportRow(month: 'Oct 2025', scope1: 0.00, scope2Gross: 1378.2, solarAvoided: 23.0),
  const BursaReportRow(month: 'Nov 2025', scope1: 0.00, scope2Gross: 1341.6, solarAvoided: 22.8),
  const BursaReportRow(month: 'Dec 2025', scope1: 0.00, scope2Gross: 1395.9, solarAvoided: 24.2),
];

// ── Carbon Intelligence Dashboard data ───────────────────────────────────────

class CarbonFlowBlock {
  final String label;
  final double percent;
  final double tco2e;
  final Color color;
  // Grid import Device ID feeding this block, set via Configure Dashboard.
  final String? deviceId;
  const CarbonFlowBlock({
    required this.label,
    required this.percent,
    required this.tco2e,
    required this.color,
    this.deviceId,
  });

  CarbonFlowBlock copyWith({String? deviceId}) => CarbonFlowBlock(
        label: label,
        percent: percent,
        tco2e: tco2e,
        color: color,
        deviceId: deviceId ?? this.deviceId,
      );
}

const kCarbonFlowBlocks = [
  CarbonFlowBlock(label: 'Block A', percent: 18, tco2e: 247.2, color: Color(0xFF64748B)),
  CarbonFlowBlock(label: 'Block B', percent: 52, tco2e: 726.8, color: Color(0xFF22C55B)),
  CarbonFlowBlock(label: 'Block C', percent: 30, tco2e: 424.9, color: Color(0xFF3B82F6)),
];

class EmissionSource {
  final String label;
  final String sublabel;
  final double percent;
  final double tco2e;
  final Color color;
  const EmissionSource({
    required this.label,
    this.sublabel = '',
    required this.percent,
    required this.tco2e,
    required this.color,
  });
}

const kEmissionBreakdown = [
  EmissionSource(label: 'Production Lines', percent: 78, tco2e: 1070.7, color: Color(0xFF22C55B)),
  EmissionSource(label: 'Utilities', sublabel: '(Chiller, AC, Pump)', percent: 22, tco2e: 301.0, color: Color(0xFF3B82F6)),
];

class CarbonContributor {
  final int rank;
  final String area;
  final double tco2e;
  final double sharePercent;
  // Selected carbon Device ID (Master Facility Setting), set via Configure Dashboard.
  final String? deviceId;
  const CarbonContributor({
    required this.rank,
    required this.area,
    required this.tco2e,
    required this.sharePercent,
    this.deviceId,
  });

  CarbonContributor copyWith({String? deviceId}) => CarbonContributor(
        rank: rank,
        area: area,
        tco2e: tco2e,
        sharePercent: sharePercent,
        deviceId: deviceId ?? this.deviceId,
      );
}

const kTopCarbonContributors = [
  CarbonContributor(rank: 1, area: 'Cast 15', tco2e: 302.4, sharePercent: 22.0),
  CarbonContributor(rank: 2, area: 'Cast 16', tco2e: 246.8, sharePercent: 18.0),
  CarbonContributor(rank: 3, area: 'Cast 17', tco2e: 219.0, sharePercent: 16.0),
  CarbonContributor(rank: 4, area: 'Chiller System', tco2e: 164.3, sharePercent: 12.0),
  CarbonContributor(rank: 5, area: 'Air Compressor', tco2e: 109.7, sharePercent: 8.0),
];

class EmissionTrendPoint {
  final String month;
  final double? actual;
  final double? target;
  final double? forecast;
  const EmissionTrendPoint({
    required this.month,
    this.actual,
    this.target,
    this.forecast,
  });
}

const kEmissionTrend = [
  EmissionTrendPoint(month: 'Jan', actual: 1120, target: 1000),
  EmissionTrendPoint(month: 'Feb', actual: 1165, target: 1050),
  EmissionTrendPoint(month: 'Mar', actual: 1210, target: 1100),
  EmissionTrendPoint(month: 'Apr', actual: 1290, target: 1150),
  EmissionTrendPoint(month: 'May', actual: 1371.7, target: 1200, forecast: 1410.0),
  EmissionTrendPoint(month: 'Jun', target: 1250, forecast: 1450),
  EmissionTrendPoint(month: 'Jul', target: 1300, forecast: 1490),
  EmissionTrendPoint(month: 'Aug', target: 1350, forecast: 1530),
  EmissionTrendPoint(month: 'Sep', target: 1400, forecast: 1570),
  EmissionTrendPoint(month: 'Oct', target: 1450, forecast: 1610),
  EmissionTrendPoint(month: 'Nov', target: 1500, forecast: 1650),
  EmissionTrendPoint(month: 'Dec', target: 1550, forecast: 1690),
];

class ProductionLineIntensity {
  final String line;
  final double productionTon;
  final double intensity;
  final double vsTargetPercent; // positive = above target (bad), negative = below (good)
  const ProductionLineIntensity({
    required this.line,
    required this.productionTon,
    required this.intensity,
    required this.vsTargetPercent,
  });
}

const kProductionLineIntensity = [
  ProductionLineIntensity(line: 'Cast 15', productionTon: 420.5, intensity: 0.72, vsTargetPercent: 12.5),
  ProductionLineIntensity(line: 'Cast 16', productionTon: 392.1, intensity: 0.63, vsTargetPercent: 4.8),
  ProductionLineIntensity(line: 'Cast 17', productionTon: 270.2, intensity: 0.81, vsTargetPercent: 21.3),
  ProductionLineIntensity(line: 'Cast 18', productionTon: 234.5, intensity: 0.69, vsTargetPercent: -6.8),
  ProductionLineIntensity(line: 'Cast 19', productionTon: 210.0, intensity: 0.63, vsTargetPercent: -4.5),
  ProductionLineIntensity(line: 'Cast 20', productionTon: 188.9, intensity: 0.57, vsTargetPercent: -13.0),
];

/// Simple normalized (0..1) sparkline series for KPI cards.
const kSparkNetEmission = [0.35, 0.42, 0.38, 0.5, 0.46, 0.6, 0.55, 0.68, 0.62, 0.74, 0.7, 0.82];
const kSparkIntensity = [0.5, 0.46, 0.55, 0.48, 0.6, 0.52, 0.58, 0.5, 0.63, 0.56, 0.6, 0.66];
const kSparkEnergy = [0.4, 0.48, 0.44, 0.55, 0.5, 0.62, 0.58, 0.7, 0.65, 0.76, 0.72, 0.84];
const kSparkSolar = [0.3, 0.42, 0.38, 0.5, 0.55, 0.48, 0.6, 0.66, 0.58, 0.7, 0.75, 0.8];
const kSparkCost = [0.38, 0.44, 0.4, 0.52, 0.48, 0.58, 0.54, 0.66, 0.6, 0.72, 0.68, 0.78];

// ── Page Model ────────────────────────────────────────────────────────────────

class CarbonEmissionModel extends FlutterFlowModel<CarbonEmissionWidget> {
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;

  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;

  String? dropDownValue3;
  FormFieldController<String>? dropDownValueController3;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    dropDownValueController1?.dispose();
    dropDownValueController2?.dispose();
    dropDownValueController3?.dispose();
  }
}
