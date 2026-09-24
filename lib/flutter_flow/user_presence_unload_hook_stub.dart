typedef LeaveHandler = void Function();

void installUnloadHook(LeaveHandler handler) {
  // No-op on non-web platforms.
}

