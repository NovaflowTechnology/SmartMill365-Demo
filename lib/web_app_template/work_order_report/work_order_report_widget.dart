import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/web_app_template/work_order_report/cubits/cubits.dart';
import 'package:smartmachine365/web_app_template/work_order_report/view.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class WorkOrderReportWidget extends StatefulWidget {
  const WorkOrderReportWidget({super.key});

  @override
  State<WorkOrderReportWidget> createState() => _WorkOrderReportWidgetState();
}

class _WorkOrderReportWidgetState extends State<WorkOrderReportWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Align(
                  alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: double.infinity,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image:
                            Image.asset('assets/images/backgroundanimated.gif')
                                .image,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: BlocProvider(
                              create: (_) => WorkOrderReportCubit(
                                  context.read<WorkOrderReportRepository>())
                                ..init(),
                              child: const WorkOrderReportView(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
