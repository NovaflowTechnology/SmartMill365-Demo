import '../models/settlement_models.dart';

/// Every number the Solar Settlement screen shows, worked out in one place.
///
/// Pure functions over the models — no HTTP, no widgets, no formatting. A
/// settlement is money between two parties, so the arithmetic has to be
/// readable on its own and has to give the same answer wherever it is called
/// from. Anything that needs a total asks here rather than summing a list it
/// happens to be holding.
class SettlementCalculator {
  const SettlementCalculator._();

  static double solarGenerated(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.solarGeneratedKwh);

  static double supplied(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.suppliedKwh);

  static double peakKwh(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.peakKwh);

  static double offPeakKwh(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.offPeakKwh);

  static double gridImport(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.gridImportKwh);

  static double peakValueRm(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.peakValueRm);

  static double offPeakValueRm(SettlementPeriod p) =>
      p.days.fold(0.0, (s, d) => s + d.offPeakValueRm);

  static double totalValueRm(SettlementPeriod p) =>
      peakValueRm(p) + offPeakValueRm(p);

  /// Share of supplied energy that fell in the peak window, 0–100.
  ///
  /// Returns null rather than zero when nothing was supplied: "0% of nothing"
  /// reads as a real finding and is not one.
  static double? peakSharePct(SettlementPeriod p) {
    final total = supplied(p);
    if (total <= 0) return null;
    return peakKwh(p) / total * 100;
  }

  static double? offPeakSharePct(SettlementPeriod p) {
    final total = supplied(p);
    if (total <= 0) return null;
    return offPeakKwh(p) / total * 100;
  }

  /// Share of generation that went to the receiving block.
  static double? suppliedSharePct(SettlementPeriod p) {
    final generated = solarGenerated(p);
    if (generated <= 0) return null;
    return supplied(p) / generated * 100;
  }

  /// What the supplying block generated, against what it can account for.
  ///
  /// The difference is the point of the check: it is the kWh that were
  /// generated and neither supplied nor recorded as self-use, and it should be
  /// zero. Reporting it as a signed number means an over-allocation shows up
  /// as readily as a shortfall.
  static ({double generated, double allocated, double difference})
      allocation(SettlementPeriod p) {
    final generated = solarGenerated(p);
    final allocated = supplied(p) + p.selfUseKwh + p.unallocatedKwh;
    return (
      generated: generated,
      allocated: allocated,
      difference: allocated - generated,
    );
  }

  /// Whether the two sides of the agreement agree, within a tolerance.
  ///
  /// Meter readings are not exact and a settlement that demanded they match to
  /// the kWh would flag every month. A tenth of a percent of the period, or
  /// 1 kWh, whichever is larger.
  static bool isReconciled(SettlementPeriod p) {
    final diff = allocation(p).difference.abs();
    final tolerance = (solarGenerated(p) * 0.001).clamp(1.0, double.infinity);
    return diff <= tolerance;
  }

  /// What the same energy would have cost from the grid.
  ///
  /// Zero when no grid tariff is configured, which the screen shows as an
  /// unavailable comparison rather than as a saving of the full amount.
  static double gridEquivalentRm(SettlementPeriod p) =>
      peakKwh(p) * p.gridTariffPeakRm + offPeakKwh(p) * p.gridTariffOffPeakRm;

  /// Grid cost avoided: what the grid would have charged, less what the
  /// receiving block pays under the agreement. Null when there is no grid
  /// tariff to compare against.
  static double? costAvoidedRm(SettlementPeriod p) {
    if (p.gridTariffPeakRm <= 0 && p.gridTariffOffPeakRm <= 0) return null;
    return gridEquivalentRm(p) - totalValueRm(p);
  }
}
