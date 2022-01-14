import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
              // await ChannelTalk.boot(
              //   pluginKey: 'dd82c5cc-12dc-403a-9368-21e04d44382b',
              //   memberId: 'test', //B2C 고객 계정ID
              //   memberHash: 'memberHash',
              //   trackDefaultEvent: false,
              //   hidePopup: false,
              //   language: 'korean',
              // );
              // await ChannelTalk.openChat();
            },
          ),
          ListTile(
            title: Text('1. Dynamic Link'),
            subtitle: SelectableText('https://chabot.page.link/76UZ'),
            onTap: () {
              launch('https://chabot.page.link/76UZ?id=event');
            },
          ),
          ListTile(
            title: Text('2. AppsFlyer Deep Link'),
            subtitle: SelectableText('https://chabot-driver.onelink.me/mvXp/303eea72'),
            onTap: () {
              launch('https://chabot-driver.onelink.me/mvXp/303eea72');
              // launch('https://chabot-driver.onelink.me/mvXp/8c5c3828?af_force_deeplink=true');
            },
          )
        ],
      )
    );
  }
}
