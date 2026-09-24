# Login & Sessions

## Overview

The login flow combines Firebase Auth with three additional layers:

1. **Account disabled check** — `account_status/{uid}` Firestore doc
2. **Single-session enforcement** — reuses the `presence/{uid}` heartbeat
3. **Cyberpunk warning toast** — replaces all login `SnackBar`s

## Login flow (step by step)

```
User taps Sign In
       │
       ▼
_login()  in  lib/login_page/login_page_widget.dart
       │
       ├─ guard: if already logging in, return
       ├─ set _isLoggingIn = true → button shows spinner
       │
       ├─ FirebaseAuth.signOut()         (clean slate)
       ├─ trim email, read password
       ├─ setPersistence(LOCAL)          (so refresh keeps user signed in)
       │
       ├─ authManager.signInWithEmail()  ── on error → cyberpunk toast, return
       │
       ├─ Firestore: account_status/{uid}.disabled == true?
       │      ├─ yes → signOut + cyberpunk toast "account disabled" → return
       │      └─ no  → continue
       │
       ├─ Firestore: presence/{uid}
       │      status == 'online' AND last_seen ≤ 90s ago?
       │      ├─ yes → signOut + cyberpunk toast "already logged in" → return
       │      └─ no  → continue
       │
       ├─ if rememberMe → save email/password to shared_preferences
       ├─ context.goNamedAuth('EquipmentOverview')
       │
       └─ finally: set _isLoggingIn = false → button returns to "Sign In"
```

After navigation, `nav.dart` calls `UserPresence.goOnline(uid)` which writes
to `presence/{uid}` and starts the 30-second heartbeat. This is what makes
single-session enforcement work for *the next* login attempt.

## Single-session enforcement

**Goal**: prevent the same account from being signed in on two devices /
browsers / tabs at once. New logins are **rejected** while another session
is active. We do **not** kick the existing session out.

**Implementation**: piggybacks on the existing `presence` system.

- `UserPresence.goOnline(uid)` writes `presence/{uid}` with `status: 'online'`
  and `last_seen: serverTimestamp()`, then updates `last_seen` every 30s
- `UserPresence.goOffline(uid)` (called on explicit logout) sets
  `status: 'offline'`
- A session is considered "live" if `status == 'online'` AND `last_seen`
  is within 90 seconds (matches the heartbeat freshness window already used
  by `UserPresence.statusStream`)
- The login flow queries this doc *after* sign-in (because we need the uid)
  and rejects if a live session exists

**Edge case (intentional)**: if a user closes the browser without logging
out, the heartbeat stops. After ~90 seconds the session is no longer "live"
and they can log back in. This is the grace period — there is no permanent
lockout.

**Failure mode**: if Firestore is unreachable during the check, the login
**fails open** (allowed). This is intentional — we don't want to block
legitimate users when the database is down.

**Files involved**:

- `lib/login_page/login_page_widget.dart` — `_login()` performs the check
- `lib/flutter_flow/user_presence.dart` — heartbeat write/read + statusStream
- `lib/flutter_flow/nav/nav.dart:509` — `goOnline` is called after auth
- `lib/web_app_template/side_nav/side_nav_widget.dart:83` — `goOffline` on logout

## Cyberpunk warning toast

A reusable top-center overlay toast styled to match the login page's sci-fi
theme. Replaces every `ScaffoldMessenger.showSnackBar` in the login flow
**and** the auth manager.

**File**: `lib/login_page/cyberpunk_warning_toast.dart`

**Usage**:

```dart
import '/login_page/cyberpunk_warning_toast.dart';

showCyberpunkWarningToast(context, 'Your message here');

// Optional custom duration
showCyberpunkWarningToast(
  context,
  'Long message',
  duration: const Duration(seconds: 6),
);
```

**Visual features**:

- Top-center popup via `OverlayEntry` (above all other UI)
- Dark gradient background (`#0A0A1F → #14142B`) at 95% opacity
- Neon border + double-layer outer glow using `theme.primary`
- Pulsing glow animation (1.4s reverse loop)
- Left neon accent bar + glowing warning icon
- Two-line text: `// SYSTEM ALERT` header (ShareTechMono font) +
  message body (Rajdhani font)
- Slide-down + fade entry (350ms easeOutCubic), reverse on dismiss
- Auto-dismiss after 4 seconds (default), or tap to dismiss early

**Color**: uses `theme.primary` for both border and accent. **Avoid
`theme.tertiary`** — that's the purple accent and was rejected for this
component.

## Where the toast is wired

| Trigger                                      | File                                          |
| -------------------------------------------- | --------------------------------------------- |
| Wrong email / password                       | `firebase_auth_manager.dart` `_showError`     |
| Account not found / too many attempts / etc. | `firebase_auth_manager.dart` `_showError`     |
| Account disabled flag                        | `login_page_widget.dart` `_login`             |
| Already logged in elsewhere                  | `login_page_widget.dart` `_login`             |
| Unexpected exception fallback                | `login_page_widget.dart` `_login` catch       |
| Other auth flows (delete, update email, etc.)| `firebase_auth_manager.dart` `_showError`     |

## Loading state on the Sign In button

The Sign In button uses an `AnimatedSwitcher` to swap between two states:

- **Idle**: "Sign In" label
- **Loading**: white circular spinner + `AUTHENTICATING...` label

While loading, `onPressed` is `null` (button disabled, dimmed to 70% opacity).
A re-entry guard `if (_isLoggingIn) return;` at the top of `_login()`
prevents double-taps from triggering parallel auth attempts.

The loading state is reset in a `finally` block so it always clears,
regardless of which path the function returned through (success, error,
disabled, single-session rejection).

## Session storage (per-user localStorage)

`lib/flutter_flow/session_storage.dart` provides a wrapper around the
browser's `localStorage`, keyed per UID. It stores:

- `sf365_active_uid` — the currently logged-in user
- `sf365_session_{uid}` — auth/profile data (role, modules, token, …)
- `sf365_settings_{uid}` — per-user UI preferences (theme, sidebar state, …)

This is **separate from** `presence/{uid}` (Firestore). Local storage is
per-browser; presence is the global source of truth used for single-session
enforcement.

## Remember Me

Uses `shared_preferences` to persist the email and password (for the demo
project). Reloaded into the form fields by `_checkRememberMe()` on page
init. **Note**: storing plain-text passwords in shared_preferences is fine
for a demo but should be revisited before production.
