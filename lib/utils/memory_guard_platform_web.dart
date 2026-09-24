import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.performance.memory.usedJSHeapSize')
external JSNumber? get _usedJsHeap;

/// The location object itself, so reload can be called *on* it.
///
/// Bound as `window.location.reload` this was a bare function reference, and a
/// browser rejects `reload()` invoked without its receiver. That threw where
/// nothing caught it, which left the guard believing a reload was already in
/// flight and stopped it checking ever again — a tab that logged "reloading"
/// once and then sat there for hours.
@JS('window.location')
external JSObject get _location;

@JS('window.location.href')
external set _locationHref(JSString value);

@JS('window.location.href')
external JSString get _locationHrefValue;

@JS('document.hidden')
external JSBoolean? get _documentHidden;

@JS('window.sessionStorage.getItem')
external JSString? _sessionGet(JSString key);

@JS('window.sessionStorage.setItem')
external void _sessionSet(JSString key, JSString value);

/// JS heap in MB, or null where `performance.memory` is unavailable
/// (everything outside Chromium).
int? readUsedHeapMb() {
  try {
    final v = _usedJsHeap;
    if (v == null) return null;
    return (v.toDartDouble / (1024 * 1024)).round();
  } catch (_) {
    return null;
  }
}

int readReloadCount() {
  try {
    return int.tryParse(_sessionGet('mg_reloads'.toJS)?.toDart ?? '') ?? 0;
  } catch (_) {
    return 0;
  }
}

void writeReloadCount(int value) {
  try {
    _sessionSet('mg_reloads'.toJS, '$value'.toJS);
  } catch (_) {
    // sessionStorage can be blocked; the counter is diagnostic only, so
    // losing it must never stop a reload from happening.
  }
}

bool isDocumentHidden() {
  try {
    return _documentHidden?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Reloads the page. Returns false when every attempt failed.
///
/// Two routes because the first can be refused: calling the method on
/// location is the normal path, and re-assigning href is what still works
/// when it is not available.
bool reloadPage() {
  try {
    _location.callMethod<JSAny?>('reload'.toJS);
    return true;
  } catch (_) {
    // fall through to the href route
  }
  try {
    _locationHref = _locationHrefValue;
    return true;
  } catch (_) {
    return false;
  }
}
