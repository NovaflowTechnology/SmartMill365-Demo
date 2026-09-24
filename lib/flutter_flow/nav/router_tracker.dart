import 'package:flutter/widgets.dart';

class RouteTracker extends ChangeNotifier {
  String _currentRoute = '/';
  String get currentRoute => _currentRoute;

  void updateRoute(String routeName) {
    _currentRoute = routeName;
    notifyListeners();
  }
}

final routeTracker = RouteTracker();
