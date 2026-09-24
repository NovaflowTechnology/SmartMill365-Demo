# side_nav

**Path**: `lib/web_app_template/side_nav/`
**Category**: Navigation & shell

## Purpose
The persistent left sidebar that wraps every authenticated screen. Renders
navigation items dynamically based on the logged-in user's role and
`accessibleModules` / `accessibleSubModules`. Also hosts the user profile
section and the logout button.

## Firestore collections
- `roles` (read) — to resolve the current user's accessible modules
- `presence` (write, indirectly) — `goOffline` is called from the logout button

## Key files
- `side_nav_widget.dart` — main widget; logout calls `UserPresence.goOffline`
- `side_nav_model.dart`

## Related modules
- All authenticated modules — every screen is rendered inside this shell
- [manage_user_groups](manage_user_groups.md) — owns the role/permission data this module reads

## Notes
- RBAC filtering happens here. If a user can't see a sidebar item, they
  can't navigate to it through the UI (route guards in `nav.dart` enforce
  it server-side as well).
- Logout side-effect: clears `presence/{uid}` so single-session enforcement
  releases the lock immediately on explicit logout.
