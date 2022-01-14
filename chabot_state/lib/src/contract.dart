import 'dart:async';

import 'package:flutter/material.dart';
import 'exceptions.dart';

part 'presenter.dart';
part 'router.dart';

class Contract {

  static final Contract _instance = Contract._();

  static Contract get instance => _instance;

  Contract._();

  final RouteInformationParser<Object> parser = _RouteInformationParser();

  _RouterDelegate? _routerDelegate;

  RouterDelegate<Object> initRouterDelegate(List<RoutePage> pages) {
    _routerDelegate ??= _RouterDelegate(this, pages);
    return _routerDelegate!;
  }

  BuildContext? get context => _routerDelegate?._navigatorKey.currentContext;

  static Future<dynamic> push(String routeName,
      {Map<String, String> queryParameter = const {}, Object? arguments}) {
    final page = Contract.instance._routerDelegate?._getPage(routeName);
    if (page != null) {
      final completer = Completer();
      final pagePresenter = _PresenterContract(
        configure: _Configure(
            Uri(
                path: routeName,
                queryParameters:
                    queryParameter.isNotEmpty ? queryParameter : null),
            arguments: arguments),
        page: page,
        popCompleter: completer,
      );
      Contract.instance._pushPagePresenter(pagePresenter);
      Contract.instance._routerDelegate?._notifyListeners();
      return completer.future;
    }

    return Future.value(null);
  }

  final List<_PresenterContract> _pagePresenters = [];

  _PresenterContract? _pagePresenterByContext(BuildContext context) {
    _PresenterContract? pagePresenter;
    if(context is StatefulElement && context.state is _ContractState) {
      pagePresenter = (context.state as _ContractState)._pagePresenter;
    } else {
      context.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is _ContractState) {
          pagePresenter = (element.state as _ContractState)._pagePresenter;
          return false;
        }
        return true;
      });
    }
    return pagePresenter;
  }

  T? _presentByContext<T extends Presenter>(BuildContext context) => _pagePresenterByContext(context)?.of<T>();

  _PresenterContract? get lastPagePresenter => _pagePresenters.isNotEmpty ? _pagePresenters.last : null;

  void _pushPagePresenter(_PresenterContract pagePresenter) {
    for (final pagePresenter in _pagePresenters) {
      pagePresenter._pausePage();
    }
    _pagePresenters.add(pagePresenter.._resumePage());
  }

  void _popPagePresenter(_PresenterContract pagePresenter, dynamic result) {
    _pagePresenters.remove(pagePresenter
      .._pausePage()
      .._didPop(result));
    lastPagePresenter?._resumePage();
  }

  void _setNewContract(_PresenterContract pagePresenter) {
    int? index;
    for(int i = _pagePresenters.length - 1; i >= 0; i--) {
      if(_pagePresenters[i].configure.uri == pagePresenter.configure.uri) {
        index = i;
        break;
      }
    }

    if(index != null) {
      for(int i = index + 1; i < _pagePresenters.length; i++) {
        _pagePresenters[i]._pausePage();
        _pagePresenters[i]._didPop(null);
      }
      _pagePresenters.removeRange(index + 1, _pagePresenters.length);
      lastPagePresenter?._resumePage();
    } else {
      _pushPagePresenter(pagePresenter);
    }
  }
}

class _PresenterContract implements PagePresenter {

  final _Configure configure;
  final RoutePage page;
  final Completer<dynamic>? popCompleter;

  _PresenterContract({required this.configure, required this.page, this.popCompleter});
  
  void _didPop(dynamic result) {
    popCompleter?.complete(result);
  }

  final Map<Type, Presenter> _presenters = {};
  bool _resume = false;
  bool _appLifecycle = false;

  BuildContext Function()? _context;

  BuildContext get context {
    final context = _context?.call();
    if(context != null) {
      return context;
    }
    throw Exceptions.CONTRACT_CONTEXT.exception;
  }

  bool _initPage(BuildContext Function() context) {
    _context = context;
    return page.binding(context(), this, configure.uri.queryParameters, configure.arguments);
  }

  void _disposePage() {
    for(final value in _presenters.values) {
      if(value is PresenterContext) {
        value._context = null;
      }
      if (value is PresenterLifeCycle) {
        value._pausePage();
      }
      value._detachContract();
    }
    _presenters.clear();

    _context = null;
  }

  void _resumePage() {
    if(!_resume) {
      _resume = true;
      for(final value in _presenters.values) {
        if (value is PresenterLifeCycle) {
          value._resumePage();
        }
      }
    }
  }

  void _pausePage() {
    if(_resume) {
      _resume = false;
      for(final value in _presenters.values) {
        if (value is PresenterLifeCycle) {
          value._pausePage();
        }
      }
    }
  }

  void _resumeAppLifecycle() {
    if(!_appLifecycle) {
      _appLifecycle = true;
      for (final value in _presenters.values) {
        if (value is PresenterLifeCycle) {
          value._resumeAppLifecycle();
        }
      }
    }
  }

  void _pauseAppLifecycle() {
    if(_appLifecycle) {
      _appLifecycle = false;
      for(final value in _presenters.values) {
        if (value is PresenterLifeCycle) {
          value._pauseAppLifecycle();
        }
      }
    }
  }

  @override
  bool put<T extends Presenter>(T presenter) {
    if(!_presenters.containsKey(T)) {
      _presenters[T] = presenter;
      presenter._attachContract();
      if(presenter is PresenterContext) {
        presenter._context = () => context;
      }
      if (presenter is PresenterLifeCycle) {
        if(_resume) {
          presenter._resumePage();
        }
        if(_appLifecycle) {
          presenter._resumeAppLifecycle();
        }
      }
      return true;
    }
    return false;
  }

  @override
  T? remove<T extends Presenter>() {
    final presenter = _presenters.remove(T);
    if (presenter is PresenterLifeCycle) {
      presenter._pauseAppLifecycle();
      presenter._pausePage();
    }
    if(presenter is PresenterContext) {
      presenter._context = null;
    }
    presenter?._detachContract();
    if(presenter is T) {
      return presenter;
    }
    return null;
  }

  @override
  T? of<T extends Presenter>() {
    final presenter = _presenters[T];
    if (presenter is T) {
      return presenter;
    }
    return null;
  }
}

class _ContractWidget extends StatefulWidget {
  final _PresenterContract pagePresenter;

  const _ContractWidget({Key? key, required this.pagePresenter}) : super(key: key);

  @override
  _ContractState createState() => _ContractState();
}

class _ContractState extends State<_ContractWidget> with WidgetsBindingObserver { // ignore: prefer_mixin

  bool _init = false;
  late final _PresenterContract _pagePresenter;

  @override
  void initState() {
    super.initState();

    _pagePresenter = widget.pagePresenter;
    try {
      final result = _pagePresenter._initPage(() => context);
      if (result == false) {
        Navigator.pop(context);
        return;
      }
    } catch (_) {
      Navigator.pop(context);
      return;
    }

    final lifecycleState = WidgetsBinding.instance?.lifecycleState;
    if(lifecycleState == AppLifecycleState.resumed) {
      _pagePresenter._resumeAppLifecycle();
    }
    WidgetsBinding.instance?.addObserver(this);

    _init = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _pagePresenter._disposePage();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.resumed) {
      _pagePresenter._resumeAppLifecycle();
    } else {
      _pagePresenter._pauseAppLifecycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _init ? _pagePresenter.page.builder(context) : Container();
  }
}

mixin ViewContract {
  void initViewContract(Presenter presenter, VoidCallback markNeedsBuild) {
    presenter.addListener(markNeedsBuild);
    presenter._attachView();
  }

  void disposeViewContract(Presenter presenter, VoidCallback markNeedsBuild) {
    presenter.removeListener(markNeedsBuild);
    presenter._detachView();
  }
}