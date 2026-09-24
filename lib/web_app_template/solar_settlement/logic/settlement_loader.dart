import 'package:smartmachine365/utils/tou_window.dart';

import '../models/settlement_config.dart';
import '../models/settlement_masters.dart';
import '../models/settlement_models.dart';
import '../services/solar_settlement_service.dart';

/// Everything one period is loaded from, decided before loading starts.
class SettlementInputs {
  const SettlementInputs({
    required this.month,
    required this.supplier,
    required this.receiver,
    required this.splitMeterId,
    this.receiveMeterId = '',
    this.rates = const SettlementRates(peakRmPerKwh: 0, offPeakRmPerKwh: 0),
    this.tnb = const TnbRates(),
    this.tnbCategoryName = '',
    this.tou,
    this.missingFill = MissingDataFill.pending,
  });

  final DateTime month;
  final SettlementBlock supplier;
  final SettlementBlock receiver;

  /// The meter whose hourly record is split into peak and non-peak — the
  /// send-side meter, or the receive-side one on a receive-side basis.
  final String splitMeterId;
  final String receiveMeterId;
  final SettlementRates rates;
  final TnbRates tnb;
  final String tnbCategoryName;
  final TouWindow? tou;
  final MissingDataFill missingFill;
}

/// Turns what the endpoints return into a [SettlementPeriod].
///
/// Sits between the service and the screen so neither has to know about the
/// other: the service does not know what a settlement is, and the widgets do
/// not know where a kWh came from.
///
/// Loading happens in two passes on purpose. The month's totals need a few
/// requests and arrive in a second; splitting each day into peak and off-peak
/// needs that day's hourly record, which is one request per day. Showing the
/// totals immediately and filling the ledger's ToU columns as they arrive
/// beats a screen that stays blank for half a minute.
class SettlementLoader {
  const SettlementLoader._();

  /// First pass: the month's energy per day, unsplit.
  static Future<SettlementPeriod> loadTotals(SettlementInputs i) async {
    final results = await Future.wait([
      SolarSettlementService.monthlyDaily(i.supplier.solarMeterId, i.month),
      SolarSettlementService.monthlyDaily(i.receiver.gridMeterId, i.month),
      i.receiveMeterId.isEmpty
          ? Future.value(const <int, double>{})
          : SolarSettlementService.monthlyDaily(i.receiveMeterId, i.month),
    ]);
    final solarByDay = results[0];
    final gridByDay = results[1];
    final receivedByDay = results[2];

    final lastDay = DateTime(i.month.year, i.month.month + 1, 0).day;
    final days = <SettlementDay>[];
    for (var d = 1; d <= lastDay; d++) {
      final solar = solarByDay[d] ?? 0;
      final grid = gridByDay[d] ?? 0;
      if (solar <= 0 && grid <= 0) continue;
      days.add(SettlementDay(
        date: DateTime(i.month.year, i.month.month, d),
        solarGeneratedKwh: solar,
        gridImportKwh: grid,
        // Unsplit until the hourly pass runs. Zero here means "not known yet",
        // and the ledger draws those cells as pending rather than as nothing
        // supplied in the peak window.
        peakKwh: 0,
        offPeakKwh: 0,
        peakRate: i.rates.peakRmPerKwh,
        offPeakRate: i.rates.offPeakRmPerKwh,
      ));
    }

    final tou = i.tou;
    return SettlementPeriod(
      month: i.month,
      supplier: i.supplier,
      receiver: i.receiver,
      rates: tou == null
          ? i.rates
          : i.rates.withWindow(
              _windowLabel(tou, peak: true), _windowLabel(tou, peak: false)),
      days: days,
      gridTariffPeakRm: i.tnb.peak,
      gridTariffOffPeakRm: i.tnb.offPeak,
      receivedKwh: i.receiveMeterId.isEmpty
          ? null
          : receivedByDay.values.fold<double>(0, (s, v) => s + v),
      tnbCategoryName: i.tnbCategoryName,
      tnbSource: i.tnb.source,
    );
  }

  /// Second pass: split each day's supply into peak and off-peak using that
  /// day's hourly record.
  ///
  /// [onProgress] is called after each batch with the period as it stands, so
  /// the ledger fills in rather than waiting for the last day. Days whose
  /// hourly record is missing keep a zero split and stay pending — unless the
  /// config asks for them to be estimated, which happens once every recorded
  /// day is in, and each estimate is flagged.
  static Future<SettlementPeriod> refineTouSplit(
    SettlementPeriod period,
    SettlementInputs i, {
    void Function(SettlementPeriod partial)? onProgress,
    bool Function()? isCancelled,
    int batchSize = 4,
  }) async {
    final tou = i.tou;
    final meter = i.splitMeterId;
    if (tou == null || period.isEmpty || meter.isEmpty) return period;

    final days = [...period.days];
    for (var k = 0; k < days.length; k += batchSize) {
      // A caller that has moved on stops the remaining requests, rather than
      // letting a month of hourly fetches finish for a result nobody reads.
      if (isCancelled?.call() ?? false) return period.withDays(days);
      final slice = days.skip(k).take(batchSize).toList();
      final hourly = await Future.wait(
        slice.map((d) => SolarSettlementService.hourlyForDay(meter, d.date)),
      );
      for (var j = 0; j < slice.length; j++) {
        final series = hourly[j];
        if (series.isEmpty) continue;
        final day = slice[j];
        final split = _splitByTou(series, tou, day.date);
        days[k + j] = _withSplit(day, split.peak, split.offPeak);
      }
      onProgress?.call(period.withDays(List.of(days)));
    }

    if (i.missingFill == MissingDataFill.interpolate) {
      final filled = _estimateMissing(days);
      final result = period.withDays(filled);
      onProgress?.call(result);
      return result;
    }
    return period.withDays(days);
  }

  /// Gives an unsplit day the month's own proportions: supply as a share of
  /// generation, and peak as a share of supply, taken from the days that do
  /// have hourly records. With no such day there is nothing to base an
  /// estimate on, and the day stays pending.
  static List<SettlementDay> _estimateMissing(List<SettlementDay> days) {
    var gen = 0.0, sup = 0.0, peak = 0.0;
    for (final d in days) {
      if (d.suppliedKwh <= 0 || d.solarGeneratedKwh <= 0) continue;
      gen += d.solarGeneratedKwh;
      sup += d.suppliedKwh;
      peak += d.peakKwh;
    }
    if (gen <= 0 || sup <= 0) return days;
    final supplyRatio = sup / gen;
    final peakShare = peak / sup;
    return [
      for (final d in days)
        if (d.suppliedKwh <= 0 && d.solarGeneratedKwh > 0)
          _withSplit(
            d,
            d.solarGeneratedKwh * supplyRatio * peakShare,
            d.solarGeneratedKwh * supplyRatio * (1 - peakShare),
            estimated: true,
          )
        else
          d,
    ];
  }

  static SettlementDay _withSplit(SettlementDay d, double peak, double offPeak,
          {bool estimated = false}) =>
      SettlementDay(
        date: d.date,
        solarGeneratedKwh: d.solarGeneratedKwh,
        gridImportKwh: d.gridImportKwh,
        peakKwh: peak,
        offPeakKwh: offPeak,
        peakRate: d.peakRate,
        offPeakRate: d.offPeakRate,
        estimated: estimated,
      );

  /// Sums an hourly series into the two ToU buckets.
  ///
  /// The window can exclude weekends, so the day's weekday decides whether any
  /// of it counts as peak at all — [TouWindow.appliesOn] already knows that
  /// rule and is not re-implemented here.
  static ({double peak, double offPeak}) _splitByTou(
      List<double> hourly, TouWindow tou, DateTime date) {
    var peak = 0.0;
    var offPeak = 0.0;
    final peakApplies = tou.appliesOn(date.weekday);
    for (var h = 0; h < hourly.length && h < 24; h++) {
      final v = hourly[h];
      if (v <= 0) continue;
      // The hour's midpoint, so an hour that straddles the boundary lands on
      // the side it mostly belongs to instead of always counting as peak.
      if (peakApplies && tou.contains(h + 0.5)) {
        peak += v;
      } else {
        offPeak += v;
      }
    }
    return (peak: peak, offPeak: offPeak);
  }

  static String _windowLabel(TouWindow tou, {required bool peak}) {
    String hhmm(double h) {
      final hours = h.floor();
      final mins = ((h - hours) * 60).round();
      return '${hours.toString().padLeft(2, '0')}:'
          '${mins.toString().padLeft(2, '0')}';
    }

    return peak
        ? '${hhmm(tou.startHour)} – ${hhmm(tou.endHour)}'
        : '${hhmm(tou.endHour)} – ${hhmm(tou.startHour)}';
  }
}
