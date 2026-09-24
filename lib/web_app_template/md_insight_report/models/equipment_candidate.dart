/// One piece of equipment eligible for a plant's Equipment Analysis ranking
/// — the candidate list the "Configure Images" settings dialog's equipment
/// checklist is built from, before any per-plant exclusions are applied.
class MdEquipmentCandidate {
  final String tag; // resolved Influx/meterId device tag
  final String label; // EquipmentItem.displayLabel

  const MdEquipmentCandidate(this.tag, this.label);
}
