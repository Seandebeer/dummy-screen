import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// In-phone web page for Flutter web, using the same sandboxed iframe as Base44.
class BrowserFrame extends StatefulWidget {
  const BrowserFrame({super.key, required this.url});

  final String url;

  @override
  State<BrowserFrame> createState() => _BrowserFrameState();
}

class _BrowserFrameState extends State<BrowserFrame> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _register(widget.url);
  }

  void _register(String url) {
    _viewType = 'browser-${identityHashCode(this)}-${url.hashCode}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final frame = web.HTMLIFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      frame.setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups',
      );
      return frame;
    });
  }

  @override
  void didUpdateWidget(BrowserFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) setState(() => _register(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
