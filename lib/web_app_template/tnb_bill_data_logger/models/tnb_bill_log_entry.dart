/// One daily row from `/energyComparison/daily-bill-log/:device_id` —
/// mirrors the columns Overall_daily_energy_consumption actually has
/// (peak_usage_kWh / off_peak_usage_kWh / max_demand_kW / power_factor_avg),
/// the same table the TNB Bill Simulator's monthly figures are summed from.
class TnbBillLogEntry {
  final DateTime date;
  final double energyKwh;
  final double peakKwh;
  final double offPeakKwh;
  final double maxDemandKw;

  /// 0 means "no PF reading that day" (several sub-meters have no PF sensor
  /// wired) — callers should treat 0 as absent, not as a real 0.000 PF.
  final double powerFactor;
  final double carbonKg;

  /// From a separate /energyDetails/solar-daily/:device_id fetch (only made
  /// when the meter has a solarDeviceId mapped) — merged in via [withSolar]
  /// after the base row is parsed, since it's a different device_id/table
  /// than the grid-import figures above. 0 means "no generation logged that
  /// day for this device", same absent-vs-zero convention as [powerFactor].
  final double solarPeakKwh;
  final double solarOffPeakKwh;

  /// Running grid-import cost from the start of this row's calendar month up
  /// to and including this day — set via [withMtdCost] after the full month
  /// is fetched (not just the display range), so it stays correct even when
  /// the table is showing a shorter 14D/90D window than the month covers.
  final double mtdCost;

  const TnbBillLogEntry({
    required this.date,
    required this.energyKwh,
    required this.peakKwh,
    required this.offPeakKwh,
    required this.maxDemandKw,
    required this.powerFactor,
    required this.carbonKg,
    this.solarPeakKwh = 0,
    this.solarOffPeakKwh = 0,
    this.mtdCost = 0,
  });

  factory TnbBillLogEntry.fromJson(Map<String, dynamic> json) {
    double p(dynamic v) {
      if (v == null) return 0.0;
      return v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    }

    return TnbBillLogEntry(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      energyKwh: p(json['energy_consumption_kWh']),
      peakKwh: p(json['peak_usage_kWh']),
      offPeakKwh: p(json['off_peak_usage_kWh']),
      maxDemandKw: p(json['max_demand_kW']),
      powerFactor: p(json['power_factor_avg']),
      carbonKg: p(json['carbon_emission_kgCO2e']),
    );
  }

  TnbBillLogEntry withSolar({required double peakKwh, required double offPeakKwh}) => TnbBillLogEntry(
        date: date,
        energyKwh: energyKwh,
        peakKwh: this.peakKwh,
        offPeakKwh: this.offPeakKwh,
        maxDemandKw: maxDemandKw,
        powerFactor: powerFactor,
        carbonKg: carbonKg,
        solarPeakKwh: peakKwh,
        solarOffPeakKwh: offPeakKwh,
        mtdCost: mtdCost,
      );

  TnbBillLogEntry withMtdCost(double mtdCost) => TnbBillLogEntry(
        date: date,
        energyKwh: energyKwh,
        peakKwh: peakKwh,
        offPeakKwh: offPeakKwh,
        maxDemandKw: maxDemandKw,
        powerFactor: powerFactor,
        carbonKg: carbonKg,
        solarPeakKwh: solarPeakKwh,
        solarOffPeakKwh: solarOffPeakKwh,
        mtdCost: mtdCost,
      );

  double peakCost(double peakRate) => peakKwh * peakRate;
  double offPeakCost(double offPeakRate) => offPeakKwh * offPeakRate;

  /// Peak cost + off-peak cost only. MD capacity/network charges, AFA and the
  /// PF surcharge are billed once per cycle from that cycle's own peak MD /
  /// average PF (see TnbE3BillSimulatorWidget._buildFromConfig) — they are
  /// not meaningfully decomposable into a single day's share, so this is
  /// intentionally a grid-import cost, not a full daily bill.
  double dayCost(double peakRate, double offPeakRate) =>
      peakCost(peakRate) + offPeakCost(offPeakRate);
}
