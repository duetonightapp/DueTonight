import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerIframeViewFactory(String viewTypeId, String embedUrl) {
  ui_web.platformViewRegistry.registerViewFactory(viewTypeId, (int viewId) {
    final iframe = web.HTMLIFrameElement();
    iframe.src = embedUrl;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    return iframe;
  });
}
