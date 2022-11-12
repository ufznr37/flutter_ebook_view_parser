
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'epub_to_html_utils.dart';

class EpubViewPage extends StatefulWidget {
  const EpubViewPage({Key? key}) : super(key: key);

  @override
  State<EpubViewPage> createState() => _EpubViewPageState();
}

class _EpubViewPageState extends State<EpubViewPage> {
  final helper = EpubToHtmlHelper();
  String? html;
  @override
  void initState() {
    helper.test('assets/sample1.epub').then((value) {
      setState(() {
        html = value;
      });
    });
    super.initState();
  }

  final Set<JavascriptChannel> jsChannels = {
    JavascriptChannel(
        name: 'Print',
        onMessageReceived: (JavascriptMessage message) {
          print('message.message: ${message.message}');
        }),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: html == null ? Center(
        child: CircularProgressIndicator(),
      ) : WebView(
        initialUrl: 'about:blank',
        javascriptMode: JavascriptMode.unrestricted,
        javascriptChannels: jsChannels,
        onWebViewCreated: (WebViewController webViewController) {
          webViewController.loadUrl(Uri.dataFromString(html!, mimeType: 'text/html',
              encoding: Encoding.getByName('utf-8')).toString());
        },
      ),
    );
  }
}