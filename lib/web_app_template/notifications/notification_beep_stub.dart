import 'package:flutter/services.dart';

/// Non-web fallback for the notification chime. There is no Web Audio API on
/// native platforms, so this plays the platform's system alert sound instead.
void playNotificationBeep() {
  SystemSound.play(SystemSoundType.alert);
}
