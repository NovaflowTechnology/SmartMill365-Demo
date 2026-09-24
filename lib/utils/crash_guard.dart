import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Stops one failing widget from taking down the whole screen.
///
/// By default a build error paints the red error box in debug and a bare grey
/// area in release, and an error high in the tree blanks everything below it.
/// On a dashboard left running in a plant that reads as a dead screen, even
/// when the rest of the page is perfectly fine.
///
/// With this installed a failing widget collapses to a small inline placeholder
/// and its siblings keep rendering, so the operator still sees every panel that
/// is working. Errors are still reported to the console — nothing is silenced,
/// only contained.
///
/// Call once from main(), before runApp().
void installCrashGuard() {
  // A build failure becomes a small marker in place of that widget rather than
  // a red box or an empty screen. Debug keeps Flutter's own diagnostics.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const _FailedPanel();
  };

  // Framework errors: log, then carry on instead of tearing down.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    previousOnError?.call(details);
    debugPrint('[CrashGuard] ${details.exceptionAsString()}');
  };

  // Uncaught async errors would otherwise reach the browser and can leave the
  // app wedged. Returning true marks them handled.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[CrashGuard] uncaught async: $error');
    return true;
  };
}

class _FailedPanel extends StatelessWidget {
  const _FailedPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        'Unavailable',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.45),
        ),
      ),
    );
  }
}
