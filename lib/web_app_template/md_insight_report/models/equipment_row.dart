/// A single row in the Equipment Analysis "Top Maximum Demand Contributors"
/// table/donut.
class EquipmentRow {
  final String name;
  final double demandKw;
  final double pctOfPeak;

  const EquipmentRow(this.name, this.demandKw, this.pctOfPeak);
}
