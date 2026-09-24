import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_models.dart';

import '../models/settlement_config.dart';
import '../models/settlement_masters.dart';
import '../models/settlement_models.dart';

/// A config joined to the master lists: the blocks as named on screen, the
/// meters behind them, and the TNB meter pricing the comparison.
class SettlementSetup {
  const SettlementSetup({
    required this.blocks,
    this.supplier,
    this.receiver,
    this.tnbPlantId = '',
    this.tnbMeter,
    this.categoryId = '',
    this.categoryName = '',
  });

  final List<SettlementBlock> blocks;
  final SettlementBlock? supplier;
  final SettlementBlock? receiver;
  final String tnbPlantId;
  final TnbMeter? tnbMeter;
  final String categoryId;
  final String categoryName;

  bool get hasAgreement =>
      supplier != null && receiver != null && supplier!.id != receiver!.id;
}

/// Follows the chain a settlement is configured through:
/// plant → its blocks → each block's TNB meter → that meter's tariff category.
///
/// Pure lookups over [SettlementMasters]; nothing here fetches or guesses. A
/// link that is missing in the masters stays missing, and the screen names the
/// setting to fix instead of filling the gap.
class SettlementSetupResolver {
  const SettlementSetupResolver._();

  /// Blocks under [plantId].
  ///
  /// The plant's own TNB meter records them — Lot 237's main meter is bound to
  /// its three block plants — so that link is used first. A plant whose meter
  /// records none falls back to plants named under it ("Lot 237 Block A").
  static List<PlantRef> blocksOf(String plantId, SettlementMasters m) {
    final parent = m.plant(plantId);
    if (parent == null) return const [];
    final ids = <String>{};
    for (final meter in metersOf(plantId, m, activeOnly: false)) {
      for (final id in meter.boundAreaIds) {
        if (id != plantId && m.plant(id) != null) ids.add(id);
      }
    }
    if (ids.isEmpty) {
      final prefix = '${parent.name.toLowerCase()} ';
      for (final p in m.plants) {
        if (p.id != plantId && p.name.toLowerCase().startsWith(prefix)) {
          ids.add(p.id);
        }
      }
    }
    final blocks = [for (final id in ids) m.plant(id)!]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return blocks;
  }

  /// "Lot 237 Block A" under "Lot 237" reads as "Block A". The plant is
  /// already on screen, and repeating it on every tab only pushes the part
  /// that differs out of view.
  static String blockName(String blockId, String plantId, SettlementMasters m) {
    final full = m.plantName(blockId);
    final parent = m.plant(plantId)?.name ?? '';
    if (parent.isEmpty || !full.toLowerCase().startsWith(parent.toLowerCase())) {
      return full;
    }
    final short = full
        .substring(parent.length)
        .replaceFirst(RegExp(r'^[\s\-—·:]+'), '')
        .trim();
    return short.isEmpty ? full : short;
  }

  static List<TnbMeter> metersOf(String plantId, SettlementMasters m,
          {bool activeOnly = true}) =>
      m.meters
          .where((x) => x.plantId == plantId && (!activeOnly || x.isActive))
          .toList();

  /// The plant whose TNB meter prices the comparison: the one chosen, or the
  /// receiving block, which is the party that would otherwise pay TNB.
  static String tnbPlantFor(SettlementConfig c) =>
      c.tnbPlantId.isNotEmpty ? c.tnbPlantId : c.receiverPlantId;

  static TnbMeter? tnbMeterFor(SettlementConfig c, SettlementMasters m) {
    final meters = metersOf(tnbPlantFor(c), m);
    if (meters.isEmpty) return null;
    for (final meter in meters) {
      if (meter.id == c.tnbMeterId) return meter;
    }
    return meters.first;
  }

  /// The category name as Tariff Category Setup writes it, or the tariff type
  /// the meter itself carries when the category is no longer active.
  static String categoryNameFor(TnbMeter? meter, SettlementMasters m) {
    if (meter == null) return '';
    final id = meter.tariffCategoryId.trim();
    return m.categoryNames[id] ??
        (meter.tariffType.trim().isNotEmpty ? meter.tariffType.trim() : id);
  }

  static SettlementSetup resolve(SettlementConfig c, SettlementMasters m) {
    final refs = [...blocksOf(c.plantId, m)];
    // A saved agreement always renders its own parties, even when the plant
    // tree has since lost the link to one of them.
    for (final id in [c.supplierPlantId, c.receiverPlantId]) {
      if (id.isNotEmpty && !refs.any((r) => r.id == id)) {
        refs.add(PlantRef(id: id, name: m.plantName(id)));
      }
    }

    SettlementBlock toBlock(PlantRef ref) {
      final meters = metersOf(ref.id, m);
      return SettlementBlock(
        id: ref.id,
        name: blockName(ref.id, c.plantId, m),
        solarMeterId: ref.id == c.supplierPlantId ? c.generationMeterId : '',
        gridMeterId: meters.isEmpty ? '' : meters.first.influxDbTag.trim(),
      );
    }

    final blocks = refs.map(toBlock).toList();
    SettlementBlock? find(String id) {
      for (final b in blocks) {
        if (b.id == id) return b;
      }
      return null;
    }

    final meter = tnbMeterFor(c, m);
    return SettlementSetup(
      blocks: blocks,
      supplier: find(c.supplierPlantId),
      receiver: find(c.receiverPlantId),
      tnbPlantId: tnbPlantFor(c),
      tnbMeter: meter,
      categoryId: meter?.tariffCategoryId.trim() ?? '',
      categoryName: categoryNameFor(meter, m),
    );
  }
}
