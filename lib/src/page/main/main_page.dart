import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:flutter/material.dart';

class MainView extends StatelessWidget {
  const MainView({
    Key? key,
  }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('1. Channel Talk'),
            onTap: () async {
              await ChannelTalk.boot(
                pluginKey: 'dd82c5cc-12dc-403a-9368-21e04d44382b',
                memberId: 'test', //B2C 고객 계정ID
                memberHash: 'memberHash',
                trackDefaultEvent: false,
                hidePopup: false,
                language: 'korean',
              );
              await ChannelTalk.openChat();
            },
          )
        ],
      )
    );
  }
}
