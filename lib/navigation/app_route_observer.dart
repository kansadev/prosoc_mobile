import 'package:flutter/material.dart';

/// Observateur global pour recharger les écrans quand ils redeviennent visibles.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
