import 'package:flutter/material.dart';

class LoadMoreScrollController {

  final ScrollController controller;
  Future<bool> Function()? _onLoadMoreListener;

  LoadMoreScrollController({ScrollController? controller})
      : controller = controller ?? ScrollController() {
    this.controller.addListener(_scrollScrollControllerListener);
  }

  void setOnLoadMoreListener(Future<bool> Function() listener) {
    _onLoadMoreListener = listener;
  }

  double? maxScrollExtent;

  void dispose() {
    controller.removeListener(_scrollScrollControllerListener);
    controller.dispose();
    _onLoadMoreListener = null;
  }

  void resetState() {
    maxScrollExtent = null;
    enableLoadMore = true;
    loadMoreState = false;
    if(controller.hasClients) {
      controller.jumpTo(0);
    }
  }

  bool enableLoadMore = true;
  bool loadMoreState = false;

  void _scrollScrollControllerListener() {
    if(enableLoadMore && !loadMoreState) {
      double maxScrollExtent = controller.position.maxScrollExtent;
      if(this.maxScrollExtent != maxScrollExtent && controller.position.maxScrollExtent - controller.offset < 100) {
        this.maxScrollExtent = controller.position.maxScrollExtent;
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    if(loadMoreState) {
      return;
    }

    loadMoreState = true;
    final loadMoreListener = _onLoadMoreListener;
    if(loadMoreListener != null) {
      enableLoadMore = await loadMoreListener();
    } else {
      enableLoadMore = false;
    }
    loadMoreState = false;
  }
}