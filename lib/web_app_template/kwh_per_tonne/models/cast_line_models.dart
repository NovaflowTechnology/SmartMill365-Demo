class CastLineModel {
  final String title;
  final String subtitle;
  final double kwhPerTonne;
  final double mainExtruderDrive;
  final double heatingZones;
  final double auxiliariesFans;
  final bool isOptimal;

  CastLineModel({
    required this.title,
    required this.subtitle,
    required this.kwhPerTonne,
    required this.mainExtruderDrive,
    required this.heatingZones,
    required this.auxiliariesFans,
    required this.isOptimal,
  });
}

class EfficiencyGapModel {
  final String message;
  final double gapPercent;

  EfficiencyGapModel({
    required this.message,
    required this.gapPercent,
  });
}

class EfficiencyShareModel {
  final String lessEfficientLabel;
  final String optimalLabel;
  final double lessEfficientRatio;

  EfficiencyShareModel({
    required this.lessEfficientLabel,
    required this.optimalLabel,
    required this.lessEfficientRatio,
  });
}

class AnalysisModel {
  final String analysisText;
  final String suggestion;

  AnalysisModel({
    required this.analysisText,
    required this.suggestion,
  });
}
