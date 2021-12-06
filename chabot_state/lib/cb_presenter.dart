import 'package:flutter/widgets.dart';

import 'cb_exception.dart';
import 'internal/cb_internal.dart';

class CBPresenter extends CBState {

}

mixin CBPresenterContext on CBPresenter {
  BuildContext Function()? onContext;

  BuildContext get context {
    final onContext = this.onContext;
    if(onContext != null) {
      return onContext();
    }
    throw CBPresenterContextException();
  }

  void pop([Object? result]) {
    final onContext = this.onContext;
    if(onContext != null) {
      final context = onContext();
      Navigator.pop(context, result);
    }
  }
}

mixin CBPresenterLifeCycle on CBPresenter {

  void onLifeCycleResume();

  void onLifeCyclePause();

  bool _resumed = false;
  bool _resumeContract = false;
  bool _resumeAppLifecycle = false;

  void resumeContract() {
    _resumeContract = true;
    _didChangeLifeCycle();
  }

  void pauseContract() {
    _resumeContract = false;
    _didChangeLifeCycle();
  }

  void resumeAppLifecycle() {
    _resumeAppLifecycle = true;
    _didChangeLifeCycle();
  }

  void pauseAppLifecycle() {
    _resumeAppLifecycle = false;
    _didChangeLifeCycle();
  }

  @override
  void didChangeAttach() {
    super.didChangeAttach();
    _didChangeLifeCycle();
  }

  void _didChangeLifeCycle() {
    final resumed = _resumeContract && _resumeAppLifecycle && isAttachView;
    if(_resumed != resumed) {
      _resumed = resumed;
      if(_resumed) {
        onLifeCycleResume();
      } else {
        onLifeCyclePause();
      }
    }
  }
}

mixin CBPresenterContainer on CBPresenter {

  bool Function<T extends CBPresenter>(T presenter, [dynamic tag])? onPutPresenter;
  T? Function<T extends CBPresenter>([dynamic tag])? onRemovePresenter;
  T? Function<T extends CBState>([dynamic tag])? onPresenterOf;

  bool putPresenter<T extends CBPresenter>(T presenter, [dynamic tag]) {
    final func = onPutPresenter;
    if(func != null) {
      return func<T>(presenter, tag);
    }

    throw CBPresenterContractException('putPresenter');
  }

  T? removePresenter<T extends CBPresenter>([dynamic tag]) {
    final func = onRemovePresenter;
    if(func != null) {
      return func<T>(tag);
    }
    throw CBPresenterContractException('removePresenter');
  }

  T? presenterOf<T extends CBPresenter>([dynamic tag]) {
    T? presenter;
    final func = onPresenterOf;
    if(func != null) {
      presenter = func<T>(tag);
    }

    if (presenter is T) {
      return presenter;
    }
    throw CBPresenterContractException('presenterOf');
  }
}

mixin CBPresenterWillPop on CBPresenter {
  Future<bool> onWillPop();
}