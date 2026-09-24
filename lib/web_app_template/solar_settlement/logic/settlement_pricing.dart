import '../models/settlement_config.dart';
import '../models/settlement_masters.dart';
import '../models/settlement_models.dart';

/// How a config becomes a price for one month.
///
/// Pure functions, shared by the dashboard and the setting page, so the rate a
/// Super Admin previews is the rate the ledger is priced at.
class SettlementPricing {
  const SettlementPricing._();

  /// The rates in effect for [month], resolved against TNB where a tier is a
  /// share of it. Zero rates when no version is in effect yet.
  static SettlementRates ratesFor(
    SettlementConfig config,
    DateTime month,
    TnbRates tnb, {
    String plantName = '',
  }) {
    final v = config.versionFor(month);
    final next = v == null ? config.nextVersionAfter(month) : null;
    return SettlementRates(
      peakRmPerKwh: v?.peak.resolve(tnb.peak) ?? 0,
      offPeakRmPerKwh: v?.offPeak.resolve(tnb.offPeak) ?? 0,
      peakDecimals: v?.peak.decimals ?? 2,
      offPeakDecimals: v?.offPeak.decimals ?? 2,
      peakFactor:
          v?.peak.mode == PricingMode.tnbFactor ? v!.peak.factor : 0,
      offPeakFactor:
          v?.offPeak.mode == PricingMode.tnbFactor ? v!.offPeak.factor : 0,
      versionLabel: v == null ? '' : versionLabel(plantName, v.version),
      effectiveFrom: v?.effectiveFrom,
      nextEffectiveFrom: next?.effectiveFrom,
    );
  }

  /// "237-SS-CFG-v1.0" for a plant named "Lot 237" — the plant's number first
  /// so versions from two plants cannot be mistaken for each other on paper.
  static String versionLabel(String plantName, int version) {
    final digits = RegExp(r'\d+').firstMatch(plantName)?.group(0) ?? '';
    final prefix = digits.isEmpty ? '' : '$digits-';
    return '${prefix}SS-CFG-v$version.0';
  }

  /// RM per kWh the receiving block saves against TNB in one window. Positive
  /// is a saving; null when either side has no rate to compare.
  static double? savingVsTnb(double tnbRate, double tierRate) {
    if (tnbRate <= 0 || tierRate <= 0) return null;
    return tnbRate - tierRate;
  }

  /// Every priced tier leaves the receiving block better off than TNB.
  static bool passesGuardrail(RateTier peak, RateTier offPeak, TnbRates tnb) {
    for (final pair in [
      (peak.resolve(tnb.peak), tnb.peak),
      (offPeak.resolve(tnb.offPeak), tnb.offPeak),
    ]) {
      final saving = savingVsTnb(pair.$2, pair.$1);
      if (saving != null && saving < 0) return false;
    }
    return true;
  }
}
