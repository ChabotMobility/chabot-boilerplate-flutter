import 'package:flutter/widgets.dart';

class ColumnSpace extends SizedBox {
  const ColumnSpace(
    double height, {
    Key? key,
  }) : super(key: key, height: height);
}

class RowSpace extends SizedBox {
  const RowSpace(
    double width, {
    Key? key,
  }) : super(key: key, width: width);
}
