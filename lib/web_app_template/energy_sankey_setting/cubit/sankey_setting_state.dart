part of 'sankey_setting_cubit.dart';

abstract class SankeySettingState extends Equatable {
  const SankeySettingState();
  @override
  List<Object?> get props => [];
}

class SankeySettingInitial extends SankeySettingState {
  const SankeySettingInitial();
}

class SankeySettingLoading extends SankeySettingState {
  const SankeySettingLoading();
}

class SankeySettingError extends SankeySettingState {
  final String message;
  const SankeySettingError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Per-tier physically separate lists. Each tier key in [nodesByTier] owns
/// its own List<SankeyNode> — modifying one list never touches another.
class SankeySettingLoaded extends SankeySettingState {
  final List<SankeyTier> tiers;
  final Map<String, List<SankeyNode>> nodesByTier;
  final List<String> devices;
  final Map<String, String> deviceLabels;
  
  /// Map of deviceId -> { fieldName: value }
  final Map<String, Map<String, double>> deviceValues;

  const SankeySettingLoaded({
    required this.tiers,
    required this.nodesByTier,
    required this.devices,
    this.deviceLabels = const {},
    this.deviceValues = const {},
  });

  List<SankeyNode> nodesInTier(String tierId) =>
      nodesByTier[tierId] ?? const <SankeyNode>[];

  /// Flat view across all tiers — used only by the save pipeline.
  List<SankeyNode> get allNodes =>
      nodesByTier.values.expand((l) => l).toList();

  /// Map of deviceId -> node Id for all non-empty mappings.
  Set<String> get usedDevices => 
      allNodes.map((n) => n.deviceId).where((id) => id.isNotEmpty).toSet();

  SankeyTier? tierById(String id) {
    try {
      return tiers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  SankeySettingLoaded copyWith({
    List<SankeyTier>? tiers,
    Map<String, List<SankeyNode>>? nodesByTier,
    List<String>? devices,
    Map<String, String>? deviceLabels,
    Map<String, Map<String, double>>? deviceValues,
  }) =>
      SankeySettingLoaded(
        tiers: tiers ?? this.tiers,
        nodesByTier: nodesByTier ?? this.nodesByTier,
        devices: devices ?? this.devices,
        deviceLabels: deviceLabels ?? this.deviceLabels,
        deviceValues: deviceValues ?? this.deviceValues,
      );

  @override
  List<Object?> get props => [tiers, nodesByTier, devices, deviceValues];
}

class SankeySettingSaving extends SankeySettingState {
  final List<SankeyTier> tiers;
  final Map<String, List<SankeyNode>> nodesByTier;
  final List<String> devices;
  const SankeySettingSaving({
    required this.tiers,
    required this.nodesByTier,
    required this.devices,
  });
  @override
  List<Object?> get props => [tiers, nodesByTier, devices];
}

class SankeySettingSaved extends SankeySettingState {
  final List<SankeyTier> tiers;
  final Map<String, List<SankeyNode>> nodesByTier;
  final List<String> devices;
  const SankeySettingSaved({
    required this.tiers,
    required this.nodesByTier,
    required this.devices,
  });
  @override
  List<Object?> get props => [tiers, nodesByTier, devices];
}

class SankeySettingSaveError extends SankeySettingState {
  final String message;
  final List<SankeyTier> tiers;
  final Map<String, List<SankeyNode>> nodesByTier;
  final List<String> devices;
  const SankeySettingSaveError({
    required this.message,
    required this.tiers,
    required this.nodesByTier,
    required this.devices,
  });
  @override
  List<Object?> get props => [message, tiers, nodesByTier, devices];
}
