import 'package:flutter/widgets.dart';

import 'cb_contract.dart';
import 'cb_exception.dart';
import 'internal/cb_internal.dart';

abstract class CBView<T extends CBState> extends StatelessWidget {
  CBView({Key? key, required BuildContext context, dynamic tag})
      : presenter = CBContract.instance.of<T>(context, tag),
        super(key: key);

  final T presenter;

  @override
  StatelessElement createElement() => _CBViewElement(this);
}

class _CBViewElement extends StatelessElement with CBViewContract {

  _CBViewElement(CBView widget) : super(widget);

  @override
  CBView get widget => super.widget as CBView;

  @override
  void mount(Element? parent, Object? newSlot) {
    initViewContract(widget.presenter, markNeedsBuild);
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    disposeViewContract(widget.presenter, markNeedsBuild);
    super.unmount();
  }
}

class CBBuilder<T extends CBState> extends StatefulWidget {
  CBBuilder({Key? key, this.tag, required this.builder, this.notFoundPresenter})
      : super(key: key);

  final dynamic tag;
  final Widget Function(BuildContext context, T presenter) builder;
  final Widget Function(BuildContext context)? notFoundPresenter;

  @override
  State<CBBuilder<T>> createState() => _CBBuilderState<T>();
}

class _CBBuilderState<T extends CBState> extends State<CBBuilder<T>> with CBViewContract {

  T? _presenter;

  @override
  void initState() {
    super.initState();

    try {
      final presenter = CBContract.instance.of<T>(context, widget.tag);
      initViewContract(presenter, _setState);
      _presenter = presenter;
    } catch(_) {}
  }

  @override
  void dispose() {
    final presenter = _presenter;
    if(presenter != null) {
      disposeViewContract(presenter, _setState);
    }
    _presenter = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presenter = _presenter;
    if(presenter != null) {
      return widget.builder(context, presenter);
    } else if(widget.notFoundPresenter != null) {
      return widget.notFoundPresenter!(context);
    }
    throw CBContractNotFoundException();
  }

  void _setState() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant CBBuilder<T> oldWidget) {
    if(_presenter == null) {
      try {
        final presenter = CBContract.instance.of<T>(context, widget.tag);
        initViewContract(presenter, _setState);
        _presenter = presenter;
      } catch(_) {}
    }

    super.didUpdateWidget(oldWidget);
  }
}