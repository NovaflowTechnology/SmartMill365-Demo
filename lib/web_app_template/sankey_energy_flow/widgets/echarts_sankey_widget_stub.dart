import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/sankey_energy_flow/widgets/sankey_chart_widget.dart';

class EchartsSankeyWidget extends StatelessWidget {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final String title;
  final String subtitle;
  final double? height;

  const EchartsSankeyWidget({
    super.key,
    required this.nodes,
    required this.links,
    this.title = 'Facility Power Distribution',
    this.subtitle = '',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SankeyChartWidget(
      nodes: nodes,
      links: links,
      title: title,
      subtitle: subtitle,
      height: height,
    );
  }
}
