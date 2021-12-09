import 'package:flutter/widgets.dart';

import '../cb_contract.dart';
import '../cb_presenter.dart';
import '../cb_service.dart';

class CBState extends ChangeNotifier {

  @protected
  @mustCallSuper
  void init() {
    _attachViewCount.addListener(didChangeAttach);
  }

  @override
  @protected
  @mustCallSuper
  void dispose() {
    _attachViewCount.removeListener(didChangeAttach);
    super.dispose();
  }

  bool _isAttachContract = false;
  bool _attachInit = false;
  bool _attachDisposed = false;

  bool get isAttachContract => _isAttachContract;

  void _attachContract() {
    if(!_isAttachContract) {
      _isAttachContract = true;
      _attachViewCount.addListener(didChangeAttach);
      didChangeAttach();
    }
  }

  void _detachContract() {
    if(_isAttachContract) {
      _isAttachContract = false;
      didChangeAttach();
    }
  }

  final ValueNotifier<int> _attachViewCount = ValueNotifier(0);

  bool get isAttachView => _attachViewCount.value > 0;

  void _attachView() => _attachViewCount.value++;
  void _detachView() => _attachViewCount.value--;

  @mustCallSuper
  void didChangeAttach() {
    if(_isAttachContract) {
      if(!_attachInit) {
        _attachInit = true;
        init();
      }
    } else if(!isAttachView && !_attachDisposed) {
      _attachDisposed = true;
      dispose();
    }
  }
}

mixin CBPresenterContracts {

  final List<CBPresenterContract> _contracts = [];

  void _pushPresenterContract(CBPresenterContract contract) {
    for (final contract in _contracts) {
      contract._pauseContract();
    }

    _contracts.add(contract.._resumeContract());
  }

  void _popPresenterContract(CBPresenterContract contract) {
    _contracts.remove(contract.._pauseContract());
    if (_contracts.isNotEmpty) _contracts.last._resumeContract();
  }

  T? presenterByContract<T extends CBState>(CBPresenterContract contract, dynamic tag) {
    bool foundContract = false;
    for(final _contract in _contracts.reversed) {
      if(!foundContract) {
        foundContract = contract == _contract;
      }

      if(foundContract) {
        final presenter = _contract.of<T>(tag);
        if(presenter is T) {
          return presenter;
        }
      }
    }
    return null;
  }
}

class _CBStateKey<T extends CBState> {
  final dynamic tag;

  _CBStateKey(this.tag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _CBStateKey &&
              runtimeType == other.runtimeType &&
              tag == other.tag;

  @override
  int get hashCode => tag.hashCode;
}

typedef CBPresenterContractCallback = void Function(CBPresenter presenter);

mixin CBPresenterContract {

  @protected
  final Map<_CBStateKey, CBState> _presenters = {};
  bool _resume = false;
  bool _appLifecycle = false;

  CBPresenterContractCallback? _initCallback;
  CBPresenterContractCallback? _disposeCallback;

  void _initContract(CBPresenterContractCallback initCallback, CBPresenterContractCallback disposeCallback) {
    _initCallback = initCallback;
    _disposeCallback = disposeCallback;
  }

  void _disposeContract() {
    for(final value in _presenters.values) {
      if (value is CBPresenterLifeCycle) {
        value.pauseContract();
      }
      value._detachContract();
      if(value is CBPresenter) {
        _disposeCallback?.call(value);
      }
    }
    _presenters.clear();

    _initCallback = null;
    _disposeCallback = null;
  }

  void _resumeContract() {
    if(!_resume) {
      _resume = true;
      for(final value in _presenters.values) {
        if (value is CBPresenterLifeCycle) {
          value.resumeContract();
        }
      }
    }
  }

  void _pauseContract() {
    if(_resume) {
      _resume = false;
      for(final value in _presenters.values) {
        if (value is CBPresenterLifeCycle) {
          value.pauseContract();
        }
      }
    }
  }

  void _resumeAppLifecycle() {
    if(!_appLifecycle) {
      _appLifecycle = true;
      for (final value in _presenters.values) {
        if (value is CBPresenterLifeCycle) {
          value.resumeAppLifecycle();
        }
      }
    }
  }

  void _pauseAppLifecycle() {
    if(_appLifecycle) {
      _appLifecycle = false;
      for(final value in _presenters.values) {
        if (value is CBPresenterLifeCycle) {
          value.pauseAppLifecycle();
        }
      }
    }
  }

  bool putPresenter<T extends CBPresenter>(T presenter, [dynamic tag]) {
    final key = _CBStateKey<T>(tag);
    if(!_presenters.containsKey(key)) {
      _presenters[key] = presenter;
      _initCallback?.call(presenter);
      presenter._attachContract();
      if (_resume && presenter is CBPresenterLifeCycle) {
        presenter.resumeContract();
      }

      return true;
    }
    return false;
  }

  T? removePresenter<T extends CBPresenter>([dynamic tag]) {
    final key = _CBStateKey<T>(tag);
    final presenter = _presenters.remove(key);
    if (presenter is CBPresenterLifeCycle) {
      presenter.pauseContract();
    }
    presenter?._detachContract();
    if(presenter is CBPresenter) {
      _disposeCallback?.call(presenter);
    }

    if(presenter is T) {
      return presenter;
    }
    return null;
  }

  T? of<T extends CBState>([dynamic tag]) {
    final presenter = _presenters[_CBStateKey<T>(tag)];
    if (presenter is T) {
      return presenter;
    }
    return null;
  }
}

mixin CBGeneratePage {

  @protected
  Widget generatePage(
      RouteSettings settings,
      bool Function(BuildContext context, CBPresenterContract contract, RouteSettings settings) binding,
      WidgetBuilder builder) =>
      _CBPageView(
        binding: (context, contract) => binding(context, contract, settings),
        builder: builder,
      );

  @protected
  Widget generatePage2nd(Map<String, dynamic> queryParameter,
      Object? arguments,
      bool Function(BuildContext context,
          CBPresenterContract contract,
          Map<String, dynamic> queryParameter,
          Object? arguments) binding,
      WidgetBuilder builder) =>
      _CBPageView(
        binding: (context, contract) => binding(context, contract, queryParameter, arguments),
        builder: builder,
      );
}

class _CBPageView extends StatefulWidget {
  final bool Function(BuildContext context, CBPresenterContract provider)? binding;
  final WidgetBuilder builder;

  const _CBPageView({Key? key, this.binding, required this.builder}) : super(key: key);

  @override
  _CBPageState createState() => _CBPageState();
}

class _CBPageState extends State<_CBPageView> with CBPresenterContract, WidgetsBindingObserver { // ignore: prefer_mixin

  bool _init = false;

  @override
  void initState() {
    super.initState();

    _initContract(_initPresenter, _disposePresenter);
    CBContract.instance._pushPresenterContract(this);
    try {
      final result = widget.binding?.call(context, this);
      if (result == false) {
        Navigator.pop(context);
        return;
      }
    } catch (_) {
      print('_CBPageState initState e : $_');
      Navigator.pop(context);
      return;
    }

    final lifecycleState = WidgetsBinding.instance?.lifecycleState;
    if(lifecycleState == AppLifecycleState.resumed) {
      _resumeAppLifecycle();
    }
    WidgetsBinding.instance?.addObserver(this);

    _init = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);

    CBContract.instance._popPresenterContract(this);
    _disposeContract();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.resumed) {
      _resumeAppLifecycle();
    } else {
      _pauseAppLifecycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _init ? widget.builder(context) : Container();
  }

  void _initPresenter(CBPresenter presenter) {
    if(presenter is CBPresenterContext) {
      presenter.onContext = () => context;
    }

    if(presenter is CBPresenterContainer) {
      presenter.onPutPresenter = putPresenter;
      presenter.onRemovePresenter = removePresenter;
      presenter.onPresenterOf = of;
    }
  }

  void _disposePresenter(CBPresenter presenter) {
    if(presenter is CBPresenterContext) {
      presenter.onContext = null;
    }

    if(presenter is CBPresenterContainer) {
      presenter.onPutPresenter = null;
      presenter.onRemovePresenter = null;
      presenter.onPresenterOf = null;
    }
  }
}

mixin CBServiceContract {

  final Map<Type, dynamic> _services = {};

  void lazyPutService<T extends CBService>(CBServiceProviderLazyPut<T> lazyPut) {
    if(!_services.containsKey(T)) {
      _services[T] = lazyPut;
    }
  }

  void putService<T extends CBService>(T service) {
    if(!_services.containsKey(T)) {
      _services[T] = service;
      service._attachContract();
    }
  }

  T? findService<T extends CBState>() {
    final service = _services[T];
    if(service is T) {
      return service;
    } else if(service is CBServiceProviderLazyPut) {
      final lazyService = service();
      if(lazyService is T) {
        _services[T] = lazyService;
        lazyService._attachContract();
        return lazyService as T;
      }
    }

    return null;
  }

  void disposeService() {
    for(final service in _services.values) {
      if(service is CBState) {
        service._detachContract();
      }
    }
    _services.clear();
  }
}

mixin CBViewContract {

  void initViewContract(CBState state, VoidCallback markNeedsBuild) {
    state.addListener(markNeedsBuild);
    state._attachView();
  }

  void disposeViewContract(CBState state, VoidCallback markNeedsBuild) {
    state.removeListener(markNeedsBuild);
    state._detachView();
  }
}