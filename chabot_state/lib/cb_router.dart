import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'cb_contract.dart';
import 'cb_page.dart';

class CBRouter {

  CBRouter();

  factory CBRouter.pages(List<CBPage> pages) {
    final router = CBRouter();
    router.initPage(pages);
    return router;
  }

  final Map<String, CBPage> _pages = {};

  void initPage(List<CBPage> pages) {
    for(final page in pages) {
      _pages[page.name] = page;
    }
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final page = _pages[settings.name];
    if(page != null) {
      return page.generateRoute(settings);
    }
  }
}

typedef CBRouterBindingPage = List<CBPage> Function();
typedef CBRouterWidgetBuilder = Widget Function(BuildContext context, CBRouter router, GlobalKey<NavigatorState> navigatorKey);

class CBRouterBuilder extends StatefulWidget{

  final CBRouterBindingPage bindingPage;
  final CBRouterWidgetBuilder builder;

  const CBRouterBuilder({Key? key, required this.bindingPage, required this.builder}) : super(key: key);

  @override
  State<CBRouterBuilder> createState() => _CBRouterState();
}

class _CBRouterState extends State<CBRouterBuilder> {

  late final CBRouter _router;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    final cbContract = CBContract.instance;
    cbContract.init(() => _navigatorKey.currentContext);
    _router = CBRouter.pages(widget.bindingPage());
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _router, _navigatorKey);
  }

  @override
  void dispose() {
    CBContract.instance.dispose();
    super.dispose();
  }
}