# manage_user_groups

**Path**: `lib/web_app_template/manage_user_groups/`
**Category**: Settings & masters

## Purpose
User account and role management. Admins create users, assign roles, and
configure which modules/submodules each role can access. The single source
of truth for the RBAC system that drives `side_nav` rendering and route
guarding.

## Firestore collections
- `roles` (read/write) — keyed by uid; stores role + accessible modules
- Firebase Auth users (via Cloud Functions in `functions/api/userFunctions.js`)
- `account_status/{uid}` (write) — sets the disabled flag

## Key files
- `user/view.dart` — list users
- `user/add.dart` — create user (creates Auth user + `roles/{uid}` doc)
- `user/edit.dart` — edit user role / permissions

## Related modules
- [side_nav](side_nav.md) — consumer of the role data
- [reports](reports.md)
- See also: `lib/login_page/login_page_widget.dart` — checks `account_status`
- See also: `functions/api/userFunctions.js` — admin Cloud Functions

## Notes
- Disabling a user here flips `account_status/{uid}.disabled = true`,
  which the login flow checks before allowing sign-in.
- Recent commits mention bug fixes around permission/role rendering —
  this module is in active development.
