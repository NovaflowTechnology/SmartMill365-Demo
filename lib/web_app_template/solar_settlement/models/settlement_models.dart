/// Data shapes for Solar Settlement.
///
/// Deliberately plain: no formatting, no colours, no widgets. A settlement is
/// an account between two blocks and it has to be auditable, so the numbers
/// move through the app as numbers and only become text at the edge that draws
/// them.
library;

import 'settlement_masters.dart';

/// One block in the agreement — the id the meters are keyed by, and the name
/// people call it.
class SettlementBlock {
  const SettlementBlock({
    required this.id,
    required this.name,
    required this.solarMeterId,
    required this.gridMeterId,
  });

  final String id;
  final String name;

  /// Meter reading this block's own solar generation. Empty when the block has
  /// no solar of its own, which is the normal case for a receiving block.
  final String solarMeterId;

  /// Meter reading this block's grid import.
  final String gridMeterId;

  bool get generates => solarMeterId.isNotEmpty;
}

/// The tariff a settlement is priced at, split by time of use.
class SettlementRates {
  const SettlementRates({
    required this.peakRmPerKwh,
    required this.offPeakRmPerKwh,
    this.peakLabel = '',
    this.offPeakLabel = '',
    this.peakDecimals = 2,
    this.offPeakDecimals = 2,
    this.peakFactor = 0,
    this.offPeakFactor = 0,
    this.versionLabel = '',
    this.effectiveFrom,
    this.nextEffectiveFrom,
  });

  final double peakRmPerKwh;
  final double offPeakRmPerKwh;

  /// Human window, e.g. "14:00 – 22:00". Empty when the ToU window is not
  /// configured, and the screen then says so rather than inventing one.
  final String peakLabel;
  final String offPeakLabel;

  final int peakDecimals;
  final int offPeakDecimals;

  /// Multiplier on TNB when a tier is priced as a share of it; zero for a
  /// fixed price.
  final double peakFactor;
  final double offPeakFactor;

  /// The published version pricing this period, e.g. "237-SS-CFG-v1.0".
  final String versionLabel;
  final DateTime? effectiveFrom;

  /// When no version is in effect yet, the month the first one starts — so an
  /// unpriced month can say when pricing begins instead of looking broken.
  final DateTime? nextEffectiveFrom;

  bool get isConfigured => peakRmPerKwh > 0 || offPeakRmPerKwh > 0;

  SettlementRates withWindow(String peak, String offPeak) => SettlementRates(
        peakRmPerKwh: peakRmPerKwh,
        offPeakRmPerKwh: offPeakRmPerKwh,
        peakLabel: peak,
        offPeakLabel: offPeak,
        peakDecimals: peakDecimals,
        offPeakDecimals: offPeakDecimals,
        peakFactor: peakFactor,
        offPeakFactor: offPeakFactor,
        versionLabel: versionLabel,
        effectiveFrom: effectiveFrom,
        nextEffectiveFrom: nextEffectiveFrom,
      );
}

/// One day of the ledger.
///
/// [peakKwh] and [offPeakKwh] are the solar supplied in each ToU window, so
/// their sum is the day's supplied energy. [gridImportKwh] is shown for
/// reference and is deliberately not part of the settlement arithmetic — a
/// receiving block's grid import says nothing about what it was supplied.
class SettlementDay {
  const SettlementDay({
    required this.date,
    required this.solarGeneratedKwh,
    required this.gridImportKwh,
    required this.peakKwh,
    required this.offPeakKwh,
    required this.peakRate,
    required this.offPeakRate,
    this.estimated = false,
  });

  final DateTime date;
  final double solarGeneratedKwh;
  final double gridImportKwh;
  final double peakKwh;
  final double offPeakKwh;
  final double peakRate;
  final double offPeakRate;

  /// True when the split was estimated because the day's hourly record never
  /// arrived. The ledger marks it, so an estimate is never read as a reading.
  final bool estimated;

  double get suppliedKwh => peakKwh + offPeakKwh;
  double get peakValueRm => peakKwh * peakRate;
  double get offPeakValueRm => offPeakKwh * offPeakRate;
  double get totalValueRm => peakValueRm + offPeakValueRm;
}

/// A whole settlement period, ready to draw.
class SettlementPeriod {
  const SettlementPeriod({
    required this.month,
    required this.supplier,
    required this.receiver,
    required this.rates,
    required this.days,
    this.selfUseKwh = 0,
    this.unallocatedKwh = 0,
    this.gridTariffPeakRm = 0,
    this.gridTariffOffPeakRm = 0,
    this.receivedKwh,
    this.tnbCategoryName = '',
    this.tnbSource = TnbRateSource.none,
  });

  final DateTime month;
  final SettlementBlock supplier;
  final SettlementBlock receiver;
  final SettlementRates rates;
  final List<SettlementDay> days;

  /// Generation the supplying block kept for itself, and generation that went
  /// nowhere recorded. Both are zero until a real allocation source exists;
  /// keeping them here means the allocation check can show that plainly
  /// instead of the screen implying every kWh was accounted for.
  final double selfUseKwh;
  final double unallocatedKwh;

  /// What the receiving block would have paid TNB for the same energy, from
  /// its TNB meter's tariff category. Zero when none resolves, and the
  /// comparison then says so.
  final double gridTariffPeakRm;
  final double gridTariffOffPeakRm;

  /// The receive-side meter's total for the period. Null when no receiving
  /// meter is mapped, which is not the same as having received nothing.
  final double? receivedKwh;

  final String tnbCategoryName;
  final TnbRateSource tnbSource;

  bool get isEmpty => days.isEmpty;

  SettlementPeriod withDays(List<SettlementDay> next) => SettlementPeriod(
        month: month,
        supplier: supplier,
        receiver: receiver,
        rates: rates,
        days: next,
        selfUseKwh: selfUseKwh,
        unallocatedKwh: unallocatedKwh,
        gridTariffPeakRm: gridTariffPeakRm,
        gridTariffOffPeakRm: gridTariffOffPeakRm,
        receivedKwh: receivedKwh,
        tnbCategoryName: tnbCategoryName,
        tnbSource: tnbSource,
      );

  static SettlementPeriod empty(DateTime month) => SettlementPeriod(
        month: month,
        supplier: const SettlementBlock(
            id: '', name: '', solarMeterId: '', gridMeterId: ''),
        receiver: const SettlementBlock(
            id: '', name: '', solarMeterId: '', gridMeterId: ''),
        rates: const SettlementRates(peakRmPerKwh: 0, offPeakRmPerKwh: 0),
        days: const [],
      );
}
