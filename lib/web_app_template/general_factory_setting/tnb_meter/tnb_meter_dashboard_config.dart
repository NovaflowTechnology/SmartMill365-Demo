/// Per-meter widget→channel mapping config for the Max Demand Monitoring
/// dashboard (24-Hour Power Load Trend, Daily Maximum Demand This Month,
/// Power Load Distribution). All three widgets read from this meter's own
/// DPM ID (SOURCE TYPE is always "PER-PLANT DEVICE") — what's configurable
/// here is the display label per widget and, for Power Load Distribution,
/// the bucket time windows each average is computed over.
class TnbDistributionBucket {
  final String key;
  final String label;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"

  const TnbDistributionBucket({
    required this.key,
    required this.label,
    required this.startTime,
    required this.endTime,
  });

  factory TnbDistributionBucket.fromJson(Map<String, dynamic> json) {
    return TnbDistributionBucket(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '00:00',
      endTime: json['endTime']?.toString() ?? '00:00',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
      };

  TnbDistributionBucket copyWith({
    String? label,
    String? startTime,
    String? endTime,
  }) {
    return TnbDistributionBucket(
      key: key,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class TnbMeterDashboardConfig {
  final String powerLoadTrendLabel;
  final String dailyMaxDemandLabel;
  final List<TnbDistributionBucket> distributionBuckets;

  const TnbMeterDashboardConfig({
    this.powerLoadTrendLabel = '24-Hour Power Load Trend',
    this.dailyMaxDemandLabel = 'Daily Maximum Demand This Month',
    this.distributionBuckets = const [],
  });

  static const List<TnbDistributionBucket> defaultBuckets = [
    TnbDistributionBucket(key: 'morning', label: 'Morning', startTime: '06:00', endTime: '12:00'),
    TnbDistributionBucket(key: 'afternoon', label: 'Afternoon', startTime: '12:00', endTime: '18:00'),
    TnbDistributionBucket(key: 'evening', label: 'Evening', startTime: '18:00', endTime: '22:00'),
    TnbDistributionBucket(key: 'night', label: 'Night', startTime: '22:00', endTime: '06:00'),
  ];

  factory TnbMeterDashboardConfig.defaults() => const TnbMeterDashboardConfig(
        distributionBuckets: defaultBuckets,
      );

  factory TnbMeterDashboardConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TnbMeterDashboardConfig.defaults();
    final rawBuckets = json['distributionBuckets'] as List<dynamic>?;
    final buckets = rawBuckets != null && rawBuckets.isNotEmpty
        ? rawBuckets.map((b) => TnbDistributionBucket.fromJson(b as Map<String, dynamic>)).toList()
        : defaultBuckets;
    return TnbMeterDashboardConfig(
      powerLoadTrendLabel: (json['powerLoadTrendLabel']?.toString() ?? '').isNotEmpty
          ? json['powerLoadTrendLabel'].toString()
          : '24-Hour Power Load Trend',
      dailyMaxDemandLabel: (json['dailyMaxDemandLabel']?.toString() ?? '').isNotEmpty
          ? json['dailyMaxDemandLabel'].toString()
          : 'Daily Maximum Demand This Month',
      distributionBuckets: buckets,
    );
  }

  Map<String, dynamic> toJson() => {
        'powerLoadTrendLabel': powerLoadTrendLabel,
        'dailyMaxDemandLabel': dailyMaxDemandLabel,
        'distributionBuckets': distributionBuckets.map((b) => b.toJson()).toList(),
      };

  TnbMeterDashboardConfig copyWith({
    String? powerLoadTrendLabel,
    String? dailyMaxDemandLabel,
    List<TnbDistributionBucket>? distributionBuckets,
  }) {
    return TnbMeterDashboardConfig(
      powerLoadTrendLabel: powerLoadTrendLabel ?? this.powerLoadTrendLabel,
      dailyMaxDemandLabel: dailyMaxDemandLabel ?? this.dailyMaxDemandLabel,
      distributionBuckets: distributionBuckets ?? this.distributionBuckets,
    );
  }
}
