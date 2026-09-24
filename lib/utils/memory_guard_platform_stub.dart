// Non-web fallback for [memory_guard.dart]'s browser primitives. MemoryGuard
// only ever calls into this on native platforms, and `start()` already
// no-ops there (see class docs), so every function below is unreachable in
// practice — they exist purely so the file compiles outside the browser.
int? readUsedHeapMb() => null;

int readReloadCount() => 0;

void writeReloadCount(int value) {}

bool isDocumentHidden() => false;

bool reloadPage() => false;
