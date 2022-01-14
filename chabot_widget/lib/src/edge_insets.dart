import 'package:flutter/widgets.dart' show EdgeInsetsDirectional;

class EdgePadding extends EdgeInsetsDirectional {
  const EdgePadding(
      {double? all,
      double? vertical,
      double? horizontal,
      double? start,
      double? top,
      double? end,
      double? bottom})
      : super.only(
          start: start ?? (horizontal ?? (all ?? 0)),
          end: end ?? (horizontal ?? (all ?? 0)),
          top: top ?? (vertical ?? (all ?? 0)),
          bottom: bottom ?? (vertical ?? (all ?? 0)),
        );
}
