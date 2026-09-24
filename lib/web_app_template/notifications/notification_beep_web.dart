// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playNotificationBeep() {
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        try {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          ctx.resume();
          var now = ctx.currentTime;

          // Classic industry "ding-dong" chime — two bell tones with natural decay
          function bell(freq, startSec, gain) {
            var o1 = ctx.createOscillator(); // fundamental
            var o2 = ctx.createOscillator(); // overtone (bell character)
            var g  = ctx.createGain();
            o1.connect(g); o2.connect(g); g.connect(ctx.destination);
            o1.type = 'sine'; o1.frequency.value = freq;
            o2.type = 'sine'; o2.frequency.value = freq * 2.756; // bell overtone ratio
            o2.connect(g);
            // sharp attack, long natural exponential decay like a real bell
            g.gain.setValueAtTime(0, now + startSec);
            g.gain.linearRampToValueAtTime(gain, now + startSec + 0.008);
            g.gain.exponentialRampToValueAtTime(0.001, now + startSec + 1.2);
            o1.start(now + startSec); o1.stop(now + startSec + 1.25);
            o2.start(now + startSec); o2.stop(now + startSec + 1.25);
          }

          bell(523.25, 0.00, 0.35); // C5 — first ding
          bell(659.25, 0.28, 0.30); // E5 — second ding (slight overlap, harmonious)
        } catch(e) { console.warn('Notification chime failed:', e); }
      })();
      '''
    ]);
  } catch (_) {}
}
