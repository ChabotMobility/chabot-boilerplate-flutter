part of 'contract.dart';

abstract class RoutePage {
  RoutePage(this.name);

  final String name;

  bool binding(BuildContext context, PagePresenter pagePresenter,
      Map<String, String> queryParameter, Object? arguments);

  Widget builder(BuildContext context);

  Page createPage(BuildContext context, Uri uri, Widget child) {
    return MaterialPage(
      key: ValueKey(uri.toString()),
      name: uri.path,
      child: child,
    );
  }
}

class _Configure {
  final Uri uri;
  final Object? arguments;

  _Configure(this.uri, {this.arguments});

  _Configure.home({this.arguments}): uri = Uri.parse('/');

  String get path => uri.path;

  List<String> get pathSegments => uri.pathSegments;
}

class _RouteInformationParser extends RouteInformationParser<_Configure> {

  const _RouteInformationParser(): super();

  @override
  Future<_Configure> parseRouteInformation(RouteInformation routeInformation) async {
    final location = routeInformation.location;
    if(location != null) {
      final uri = Uri.parse(location);
      return _Configure(uri, arguments: routeInformation.state);
    }

    return _Configure.home(arguments: routeInformation.state);
  }

  @override
  RouteInformation? restoreRouteInformation(_Configure configuration) {
    return RouteInformation(
      location: configuration.uri.toString(),
      state: configuration.arguments
    );
  }
}

class _RouterDelegate extends RouterDelegate<_Configure>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<_Configure> {   // ignore: prefer_mixin

  final Contract contract;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  _RouterDelegate(this.contract, List<RoutePage> pages) {
    this.pages = {};
    for (final page in pages) {
      this.pages[page.name] = page;
    }
  }

  late final Map<String, RoutePage> pages;

  @override
  _Configure? get currentConfiguration =>
      contract.lastPagePresenter?.configure ?? _Configure.home();

  @override
  Widget build(BuildContext context) {
    List<Page> stack = contract._pagePresenters
        .map((e) => e.page
            .createPage(context, e.configure.uri, _ContractWidget(pagePresenter: e)))
        .toList();

    if(stack.isEmpty) {
      stack.add(MaterialPage(child: Container()));
    }

    return Navigator(
      key: navigatorKey,
      pages: stack,
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        final name = route.settings.name;
        if(name != null && _popPage(name, result)) {
          notifyListeners();
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(_Configure configure) async {
    final page = pages[configure.path];
    if(page != null) {
      contract._setNewContract(_PresenterContract(configure: configure, page: page));
    }
    notifyListeners();
  }

  bool _popPage(String name, dynamic result) {
    for(final pagePresenter in contract._pagePresenters.reversed) {
      if(pagePresenter.configure.uri.toString() == name) {
        contract._popPagePresenter(pagePresenter, result);
        return true;
      }
    }
    return false;
  }

  RoutePage? _getPage(String name) {
    return pages[name];
  }

  void _notifyListeners() => notifyListeners();
}