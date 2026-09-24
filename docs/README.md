# SMARTMACHINE365 — Documentation

Developer documentation for the SMARTMACHINE365 / SMARTFACTORY365 demo project.
A Flutter web application built on FlutterFlow + Firebase, used to visualize
real-time machine and energy data for manufacturing sites.

> Collaboration: Novaflow Technology Sdn. Bhd.

## Index

1. **[Getting Started](getting-started.md)** — clone, install, configure Firebase, run locally
2. **[Architecture](architecture.md)** — folder structure, tech stack, data flow, auth flow
3. **[Modules](modules.md)** — what each feature module does
4. **[Backend](backend.md)** — Firestore collections, Cloud Functions, security rules
5. **[Login & Sessions](login-and-sessions.md)** — auth flow, single-session enforcement, presence, cyberpunk toast
6. **[Permissions / RBAC](permissions.md)** — roles, accessible modules/submodules
7. **[Git Workflow](git-workflow.md)** — `dip/dev` → `main` branching strategy
8. **[Troubleshooting](troubleshooting.md)** — common issues + fixes

## Quick links

- Repo root: `../README.md`
- Flutter version & dependencies: `../pubspec.yaml`
- Cloud Functions: `../functions/`
- Firebase config: `../firebase.json`, `../firestore.rules`

## Conventions

- Branches: feature work happens on `dip/dev`, then merges into `main`
- Editable scope (per current team agreement): `tnb_e3_bill_simulator/`,
  `kwh_tone/`, `master_facility_setting/`, `energy_details/`, `card_widget/`
  — other modules require explicit access
- All snackbars on the login flow are routed through the cyberpunk warning
  toast (`lib/login_page/cyberpunk_warning_toast.dart`)
