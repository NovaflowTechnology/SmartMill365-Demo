import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/cell_state_model.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/response.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/last_24h_chart_response.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/placeholder_widget.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/equipment_md_ranking_chart_widget.dart';
import 'package:smartmachine365/web_app_template/energy_comparison/powerconsumptionenergydetailscard_widget.dart';
import 'package:smartmachine365/web_app_template/energy_comparison/Powerconsumptionhourlyenergydetailscard_widget.dart';
import 'package:smartmachine365/web_app_template/energy_details/Powerconsumptionhourlyenergydetailscard_widget.dart' as energy_details;
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/available_panel_widget.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/frequent_use_templates_panel_widget.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/kanban_settings_panel_widget.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/select_dialog_widget.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/widget_config_dialog.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/daily_max_demand_chart_widget.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/equipment_load_correlation_chart_widget.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/equipment_md_ranking_chart_widget.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/power_load_distribution_chart_widget.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/power_load_trend_chart_widget.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/yearonyear_analaysis_chart_widget.dart';

class KanbanPanelBuilderWidget {
  static const List<String> _durationOptions = ['5s', '1m', '5m', '15m', '30m', '1h', '4h', '12h', '24h'];

  static Widget build({
    required int cellIndex,
    required String widgetType,
    required String widgetName,
    required Map<String, dynamic> config,
    required CellStateModel state,
    required VoidCallback onRefresh,
    required void Function(String date, String start, String end) onDateChanged,
  }) {
    final result = state.result;

    // Show a loading spinner for any widget while its fetch is in flight.
    if (result is LoadingResponse) {
      return Builder(builder: (context) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        return Center(
          child: CircularProgressIndicator(
            color: isLight
                ? FlutterFlowTheme.of(context).primary.withOpacity(0.4)
                : Colors.white38,
            strokeWidth: 2,
          ),
        );
      });
    }

    // Show a unified error view for any widget that errored.
    if (result is ErrorResponse) {
      return Center(
        child: Text(
          result.error ?? 'Unknown error',
          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Switch on the concrete result type — the compiler enforces exhaustiveness
    // on the sealed class, so adding a new chart model will flag missing cases.
    switch (result) {
      case MdRankingResponse():
        return EquipmentMdRankingChart(
          title: widgetName,
          selectedEventDate: config['eventDate'] as String? ?? '',
          selectedEventStart: config['eventStart'] as String? ?? '',
          selectedEventEnd: config['eventEnd'] as String? ?? '',
          rankingData: result.data,
          isLoading: false,
          errorMessage: null,
          onRefresh: onRefresh,
          onDateChanged: onDateChanged,
        );

      // ── Energy Comparison ──────────────────────────────────────────────────

      case HourlyChartResponse():
        return PowerconsumptionhourlyenergydetailscardWidget(
          title: widgetName,
          chartData: result.data,
          chartDataPrevious: result.previousData,
          isLoading: false,
          selectedDate: result.selectedDate,
          onDateChanged: (newDate) {
            onDateChanged(newDate.toIso8601String(), '', '');
          },
        );

      case DailyChartResponse():
        return PowerconsumptionenergydetailscardWidget(
          title: widgetName,
          chartData: result.data,
          isLoading: false,
          period: result.period,
        );

      case MonthlyChartResponse():
        return PowerconsumptionenergydetailscardWidget(
          title: widgetName,
          chartData: result.data,
          isLoading: false,
          period: result.period,
        );

      case YearOverYearChartResponse():
        return PowerconsumptionenergydetailscardWidget(
          title: widgetName,
          chartData: result.data,
          isLoading: false,
          period: 'Yearly',
        );

      // ── Energy Details ─────────────────────────────────────────────────────

      case Last24hChartResponse():
        return energy_details.PowerconsumptionhourlyenergydetailscardWidget(
          title: widgetName,
          chartData: result.data,
          chartDataPrevious: result.previousData,
          isLoading: false,
          selectedDate: DateTime.now(),
          selectedDuration: config['duration'] as String? ?? '1h',
          durationOptions: _durationOptions,
          onDateChanged: (newDate) {
            final duration = config['duration'] as String? ?? '1h';
            onDateChanged(newDate.toIso8601String(), duration, '');
          },
          onDurationChanged: (newDuration) {
            onDateChanged(DateTime.now().toIso8601String(), newDuration, '');
          },
        );

      // ── Max Demand Monitoring ──────────────────────────────────────────────

      case PowerLoadTrend24hResponse():
        return PowerLoadTrendChart(
          title: widgetName,
          powerLoadData: result.powerLoadData,
          isLoading: false,
          errorMessage: null,
          onRefresh: onRefresh,
          maxPowerKw: result.maxPowerKw,
          contractCapacity: result.contractCapacity,
        );

      case DailyMaxDemandResponse():
        return DailyMaxDemandChart(
          title: widgetName,
          chartData: result.data,
          isLoading: false,
          errorMessage: null,
          onRefresh: onRefresh,
          contractCapacity: result.contractCapacity,
        );

      case PowerLoadDistributionResponse():
        return PowerLoadDistributionChart(
          title: widgetName,
          distributionData: result.data,
          isLoading: false,
          errorMessage: null,
          onRefresh: onRefresh,
        );

      case YearOnYearAnalysisResponse():
        return YearOnYearAnalysisChart(
          title: widgetName,
          chartData: result.data,
          comparisonYearData: result.comparisonYearData,
          contractCapacity: result.contractCapacity,
          isLoading: false,
          errorMessage: null,
          onRefresh: onRefresh,
        );

      case EquipmentLoadCorrelationResponse():
        // ✅ Mirrors MaxDemandMonitoring Row 3 left chart — all data comes from
        // result, not hardcoded empty values. interval change encodes new
        // interval into the 'end' slot of onDateChanged so the Kanban cell
        // controller can pick it up and re-fetch with the new interval.
        return EquipmentLoadCorrelationChart(
          title: widgetName,
          selectedEventDate: result.selectedEventDate,
          selectedEventStart: result.selectedEventStart,
          selectedEventEnd: result.selectedEventEnd,
          seriesData: result.seriesData,
          deviceIds: result.deviceIds,
          systemPeak: result.systemPeak,
          isLoading: false,
          errorMessage: null,
          selectedInterval: config['interval'] as String? ?? '30m',
          onRefresh: onRefresh,
          onIntervalChanged: (newInterval) {
            // encode: date=eventDate, start=eventStart, end=newInterval
            // the cell controller reads end as the new interval for re-fetch
            onDateChanged(
              result.selectedEventDate,
              result.selectedEventStart,
              newInterval,
            );
          },
          onDateChanged: onDateChanged,
        );

      // null result — cell has been registered but fetch hasn't started yet.
      case null:
        return PlaceholderWidget(widgetName: widgetName, widgetType: widgetType, state: state);
      default:
        // Fallback in case a new result type is added but not handled above.
        return PlaceholderWidget(widgetName: widgetName, widgetType: widgetType, state: state);
    }
  }
}
