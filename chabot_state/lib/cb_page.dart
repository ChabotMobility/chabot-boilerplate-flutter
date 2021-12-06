import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'internal/cb_internal.dart';

abstract class CBPage with CBGeneratePage {
  CBPage(this.name);

  final String name;

  bool binding(BuildContext context, CBPresenterContract contract, RouteSettings settings);

  Widget builder(BuildContext context);

  Route<dynamic> generateRoute(RouteSettings settings) => MaterialPageRoute(
      settings: settings,
      builder: (context) =>
          generatePage(settings, binding, builder));
}