import 'dart:html' as html;

typedef LeaveHandler = void Function();

bool _installed = false;

void installUnloadHook(LeaveHandler handler) {
  if (_installed) return;
  _installed = true;

  void onLeave(html.Event _) => handler();
  html.window.addEventListener('pagehide', onLeave);
  html.window.addEventListener('beforeunload', onLeave);
}

