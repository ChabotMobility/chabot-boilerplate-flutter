import 'package:flutter/widgets.dart';

import 'cb_exception.dart';
import 'internal/cb_internal.dart';

class CBContract with CBPresenterContracts, CBServiceContract {
  static final CBContract _instance = CBContract._();

  static CBContract get instance => _instance;

  CBContract._();

  BuildContext? Function()? _contractContext;

  void init(BuildContext? Function()? context) {
    _contractContext = context;
  }

  void dispose() {
    _contractContext = null;
    disposeService();
  }

  BuildContext? get contractContext => _contractContext?.call();

  T of<T extends CBState>(BuildContext context, [dynamic tag]) {
    if(tag == null) {
      T? service = findService<T>();
      if(service != null) {
        return service;
      }
    }

    CBPresenterContract? contract = _findCBPresenterContract(context);
    if(contract != null) {
      return presenterOf<T>(contract, tag);
    }

    throw CBContractNotFoundException();
  }

  T presenterOf<T extends CBState>(CBPresenterContract contract, [dynamic tag]) {
    T? notifier = presenterByContract(contract, tag);
    if(notifier != null) {
      return notifier;
    }

    throw CBPresenterNotFoundException();
  }

  CBPresenterContract? _findCBPresenterContract(BuildContext context) {
    CBPresenterContract? contract;
    if(context is StatefulElement && context.state is CBPresenterContract) {
      contract = context.state as CBPresenterContract;
    } else {
      context.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is CBPresenterContract) {
          contract = element.state as CBPresenterContract;
          return false;
        }
        return true;
      });
    }
    return contract;
  }

  T serviceOf<T extends CBState>() {
    final service = findService<T>();
    if(service != null) {
      return service;
    }
    throw CBContractNotFoundException();
  }
}

extension CBContractBuildContext on BuildContext {
  T presenterOf<T extends CBState>([dynamic tag]) => CBContract.instance.of(this, tag);
}