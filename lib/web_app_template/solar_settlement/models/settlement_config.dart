/// What a Super Admin decides about a settlement, as data.
///
/// Everything the Solar Settlement Setting page edits lives here, and the
/// dashboard reads nothing else to know which blocks, meters and prices are in
/// play. Plain values only — the page turns them into controls, the loader
/// turns them into a ledger — so the terms of an agreement can be read,
/// compared and versioned without touching a widget.
library;

/// The five hero cards across the top of the dashboard.
abstract class KpiKeys {
  static const generation = 'generation';
  static const supplied = 'supplied';
  static const peak = 'peak';
  static const offPeak = 'offPeak';
  static const total = 'total';

  static const all = [generation, supplied, peak, offPeak, total];

  /// The label a card carries until someone renames it.
  static String defaultLabel(String key, String receiverName) => switch (key) {
        generation => 'Solar Generation',
        supplied =>
          'Supplied to ${receiverName.isEmpty ? 'receiver' : receiverName}',
        peak => 'Peak Solar',
        offPeak => 'Non-Peak Solar',
        total => 'Total Settlement Value',
        _ => key,
      };
}

/// How one hero card is labelled and how precisely it states its figure.
class KpiDisplay {
  const KpiDisplay({this.label = '', this.decimals = 0});

  /// Empty means the default label. Stored empty rather than as a copy of the
  /// default, so a default that mentions the receiving block keeps following
  /// it when the agreement changes.
  final String label;
  final int decimals;

  KpiDisplay copyWith({String? label, int? decimals}) => KpiDisplay(
        label: label ?? this.label,
        decimals: decimals ?? this.decimals,
      );

  Map<String, dynamic> toJson() => {'label': label, 'decimals': decimals};

  static KpiDisplay fromJson(Object? json, KpiDisplay fallback) {
    if (json is! Map) return fallback;
    return KpiDisplay(
      label: json['label']?.toString() ?? fallback.label,
      decimals: _int(json['decimals'], fallback.decimals),
    );
  }
}

enum PricingMode { fixed, tnbFactor }

/// One time-of-use tier of the agreed price.
class RateTier {
  const RateTier({
    this.mode = PricingMode.fixed,
    this.price = 0,
    this.factor = 0,
    this.decimals = 2,
  });

  final PricingMode mode;

  /// RM per kWh, used when [mode] is fixed.
  final double price;

  /// Multiplier on the TNB rate for the same window, used when [mode] is
  /// tnbFactor — 0.9 means the receiving block pays ninety percent of TNB.
  final double factor;

  final int decimals;

  /// The RM/kWh this tier charges. A factor with no TNB rate to multiply
  /// resolves to zero, which the dashboard shows as unpriced rather than free.
  double resolve(double tnbRate) {
    if (mode == PricingMode.fixed) return price > 0 ? price : 0;
    return tnbRate > 0 && factor > 0 ? tnbRate * factor : 0;
  }

  RateTier copyWith({
    PricingMode? mode,
    double? price,
    double? factor,
    int? decimals,
  }) =>
      RateTier(
        mode: mode ?? this.mode,
        price: price ?? this.price,
        factor: factor ?? this.factor,
        decimals: decimals ?? this.decimals,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'price': price,
        'factor': factor,
        'decimals': decimals,
      };

  static RateTier fromJson(Object? json) {
    if (json is! Map) return const RateTier();
    return RateTier(
      mode: json['mode'] == PricingMode.tnbFactor.name
          ? PricingMode.tnbFactor
          : PricingMode.fixed,
      price: _double(json['price']),
      factor: _double(json['factor']),
      decimals: _int(json['decimals'], 2),
    );
  }
}

/// A published set of prices and the month they take effect from.
///
/// Prices change and old invoices must not change with them, so a new price
/// is a new version rather than an edit: each month is priced by the latest
/// version already in effect for it.
class RateVersion {
  const RateVersion({
    required this.version,
    required this.effectiveFrom,
    required this.peak,
    required this.offPeak,
    this.savedAt,
    this.savedBy = '',
  });

  final int version;

  /// First day of the month the version applies from.
  final DateTime effectiveFrom;
  final RateTier peak;
  final RateTier offPeak;
  final DateTime? savedAt;
  final String savedBy;

  Map<String, dynamic> toJson() => {
        'version': version,
        'effectiveFrom': monthKey(effectiveFrom),
        'peak': peak.toJson(),
        'offPeak': offPeak.toJson(),
        if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
        'savedBy': savedBy,
      };

  static RateVersion? fromJson(Object? json) {
    if (json is! Map) return null;
    final month = parseMonthKey(json['effectiveFrom']?.toString());
    final version = _int(json['version'], 0);
    if (month == null || version <= 0) return null;
    return RateVersion(
      version: version,
      effectiveFrom: month,
      peak: RateTier.fromJson(json['peak']),
      offPeak: RateTier.fromJson(json['offPeak']),
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? ''),
      savedBy: json['savedBy']?.toString() ?? '',
    );
  }
}

/// Which meter the settlement is billed from.
enum SettlementBasis { sendSide, receiveSide }

/// What happens to a day whose hourly record never arrived.
enum MissingDataFill { pending, interpolate }

class SettlementConfig {
  const SettlementConfig({
    this.plantId = 'SITE004',
    this.supplierPlantId = 'SITE001',
    this.receiverPlantId = 'SITE002',
    this.basis = SettlementBasis.sendSide,
    this.generationMeterId = 'SOLAR001',
    this.sendMeterId = 'SOLAR001',
    this.receiveMeterId = '',
    this.missingFill = MissingDataFill.pending,
    this.kpis = defaultKpis,
    this.versions = const [],
    this.tnbPlantId = '',
    this.tnbMeterId = '',
    this.billReference = '',
    this.touSourceUid = '',
    this.updatedBy = '',
    this.updatedAt,
  });

  /// The plant the agreement sits under. Its blocks are the parties.
  final String plantId;
  final String supplierPlantId;
  final String receiverPlantId;
  final SettlementBasis basis;

  /// Meter read for "Solar Generation".
  final String generationMeterId;

  /// Meter read for what left the supplying block. Split hour by hour into
  /// peak and non-peak on a send-side basis.
  final String sendMeterId;

  /// Meter read for what arrived at the receiving block. Empty when none is
  /// mapped, and reconciliation then says it is checking the ledger only.
  final String receiveMeterId;

  final MissingDataFill missingFill;
  final Map<String, KpiDisplay> kpis;
  final List<RateVersion> versions;

  /// Plant whose TNB meter prices the comparison. Empty follows the receiving
  /// block, which is the one that would otherwise have paid TNB.
  final String tnbPlantId;

  /// TNB meter document id. Empty picks that plant's first active meter.
  final String tnbMeterId;

  final String billReference;

  /// Whose Energy System Settings hold the Peak Hour ToU window. Recorded on
  /// save, because that window is stored per user and every viewer of the
  /// settlement has to split the day the same way.
  final String touSourceUid;

  final String updatedBy;
  final DateTime? updatedAt;

  static const defaultKpis = <String, KpiDisplay>{
    KpiKeys.generation: KpiDisplay(),
    KpiKeys.supplied: KpiDisplay(),
    KpiKeys.peak: KpiDisplay(),
    KpiKeys.offPeak: KpiDisplay(),
    KpiKeys.total: KpiDisplay(decimals: 2),
  };

  KpiDisplay kpi(String key) =>
      kpis[key] ?? defaultKpis[key] ?? const KpiDisplay();

  /// The last version saved, whatever month it takes effect from.
  RateVersion? get latestVersion {
    RateVersion? best;
    for (final v in versions) {
      if (best == null || v.version > best.version) best = v;
    }
    return best;
  }

  /// The version that prices [month]: the newest one already in effect.
  RateVersion? versionFor(DateTime month) {
    final target = month.year * 12 + month.month;
    RateVersion? best;
    for (final v in versions) {
      final from = v.effectiveFrom.year * 12 + v.effectiveFrom.month;
      if (from > target) continue;
      if (best == null ||
          v.effectiveFrom.isAfter(best.effectiveFrom) ||
          (v.effectiveFrom == best.effectiveFrom && v.version > best.version)) {
        best = v;
      }
    }
    return best;
  }

  /// The earliest version that only starts after [month], so a month with no
  /// price can say when one begins.
  RateVersion? nextVersionAfter(DateTime month) {
    final target = month.year * 12 + month.month;
    RateVersion? best;
    for (final v in versions) {
      final from = v.effectiveFrom.year * 12 + v.effectiveFrom.month;
      if (from <= target) continue;
      if (best == null || v.effectiveFrom.isBefore(best.effectiveFrom)) {
        best = v;
      }
    }
    return best;
  }

  SettlementConfig copyWith({
    String? plantId,
    String? supplierPlantId,
    String? receiverPlantId,
    SettlementBasis? basis,
    String? generationMeterId,
    String? sendMeterId,
    String? receiveMeterId,
    MissingDataFill? missingFill,
    Map<String, KpiDisplay>? kpis,
    List<RateVersion>? versions,
    String? tnbPlantId,
    String? tnbMeterId,
    String? billReference,
    String? touSourceUid,
    String? updatedBy,
    DateTime? updatedAt,
  }) =>
      SettlementConfig(
        plantId: plantId ?? this.plantId,
        supplierPlantId: supplierPlantId ?? this.supplierPlantId,
        receiverPlantId: receiverPlantId ?? this.receiverPlantId,
        basis: basis ?? this.basis,
        generationMeterId: generationMeterId ?? this.generationMeterId,
        sendMeterId: sendMeterId ?? this.sendMeterId,
        receiveMeterId: receiveMeterId ?? this.receiveMeterId,
        missingFill: missingFill ?? this.missingFill,
        kpis: kpis ?? this.kpis,
        versions: versions ?? this.versions,
        tnbPlantId: tnbPlantId ?? this.tnbPlantId,
        tnbMeterId: tnbMeterId ?? this.tnbMeterId,
        billReference: billReference ?? this.billReference,
        touSourceUid: touSourceUid ?? this.touSourceUid,
        updatedBy: updatedBy ?? this.updatedBy,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  SettlementConfig withKpi(String key, KpiDisplay display) =>
      copyWith(kpis: {...kpis, key: display});

  Map<String, dynamic> toJson() => {
        'plantId': plantId,
        'supplierPlantId': supplierPlantId,
        'receiverPlantId': receiverPlantId,
        'basis': basis.name,
        'generationMeterId': generationMeterId,
        'sendMeterId': sendMeterId,
        'receiveMeterId': receiveMeterId,
        'missingFill': missingFill.name,
        'kpis': {for (final k in KpiKeys.all) k: kpi(k).toJson()},
        'versions': [for (final v in versions) v.toJson()],
        'tnbPlantId': tnbPlantId,
        'tnbMeterId': tnbMeterId,
        'billReference': billReference,
        'touSourceUid': touSourceUid,
        'updatedBy': updatedBy,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static SettlementConfig fromJson(Map json) {
    const d = SettlementConfig();
    final rawKpis = json['kpis'];
    final rawVersions = json['versions'];
    return SettlementConfig(
      plantId: _str(json['plantId'], d.plantId),
      supplierPlantId: _str(json['supplierPlantId'], d.supplierPlantId),
      receiverPlantId: _str(json['receiverPlantId'], d.receiverPlantId),
      basis: json['basis'] == SettlementBasis.receiveSide.name
          ? SettlementBasis.receiveSide
          : SettlementBasis.sendSide,
      generationMeterId: _str(json['generationMeterId'], d.generationMeterId),
      sendMeterId: _str(json['sendMeterId'], d.sendMeterId),
      receiveMeterId: json['receiveMeterId']?.toString() ?? '',
      missingFill: json['missingFill'] == MissingDataFill.interpolate.name
          ? MissingDataFill.interpolate
          : MissingDataFill.pending,
      kpis: {
        for (final k in KpiKeys.all)
          k: KpiDisplay.fromJson(
              rawKpis is Map ? rawKpis[k] : null, d.kpi(k)),
      },
      versions: rawVersions is List
          ? rawVersions.map(RateVersion.fromJson).whereType<RateVersion>().toList()
          : const [],
      tnbPlantId: json['tnbPlantId']?.toString() ?? '',
      tnbMeterId: json['tnbMeterId']?.toString() ?? '',
      billReference: json['billReference']?.toString() ?? '',
      touSourceUid: json['touSourceUid']?.toString() ?? '',
      updatedBy: json['updatedBy']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

DateTime? parseMonthKey(String? s) {
  final m = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(s?.trim() ?? '');
  if (m == null) return null;
  final month = int.parse(m.group(2)!);
  if (month < 1 || month > 12) return null;
  return DateTime(int.parse(m.group(1)!), month, 1);
}

String _str(Object? v, String fallback) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? fallback : s;
}

int _int(Object? v, int fallback) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _double(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
