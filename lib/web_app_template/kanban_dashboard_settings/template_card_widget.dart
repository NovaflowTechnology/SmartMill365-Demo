import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class TemplateCardWidget extends StatelessWidget {
  final String id;
  final String label;
  final String remark;
  final bool isBlank;
  final bool isSelected;
  final VoidCallback onTap;

  const TemplateCardWidget({
    required this.id,
    required this.label,
    required this.remark,
    required this.isBlank,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF001055),
          border: Border.all(
            color: isSelected ? primary : primary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isBlank
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: primary, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'AddBlank\nKanban',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(7)),
                      child: Container(
                        color: const Color(0xFF001A7A),
                        child: const Center(
                          child: Icon(Icons.dashboard,
                              color: Colors.blue, size: 28),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 9,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Remark: $remark',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 8,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}