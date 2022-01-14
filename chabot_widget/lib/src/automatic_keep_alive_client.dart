import 'package:flutter/widgets.dart';

class AutomaticKeepAliveClient extends StatefulWidget {
  final WidgetBuilder builder;

  const AutomaticKeepAliveClient({Key? key, required this.builder}) : super(key: key);

  @override
  _AutomaticKeepAliveClientState createState() => _AutomaticKeepAliveClientState();
}

class _AutomaticKeepAliveClientState extends State<AutomaticKeepAliveClient> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context);
  }

  @override
  bool get wantKeepAlive => true;
}