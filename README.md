# HydroFix Technical Notes

HydroFix is a Flutter application for reporting, tracking, assigning, and resolving public water problems. It provides three product roles:

- Citizen: report issues, provide severity and location details, attach photos, and track complaints.
- Professional: accept or reject jobs and move work through offered, accepted, on-the-way, in-progress, completed, and confirmed states.
- BMC administrator: monitor complaints and ward professionals, approve or reject applications, and assign jobs.

The current application is a Supabase-backed mobile-first UI. Some folders contain longer-term or alternate feature implementations, while the active entry point is currently concentrated in `lib/features/stitch_ui/hydrofix_stitch_screens.dart`.

## Runtime entry path

```text
lib/main.dart
  -> lib/bootstrap.dart
  -> lib/app.dart
  -> lib/features/stitch_ui/hydrofix_stitch_screens.dart
```

1. `main()` calls `bootstrap()`.
2. `bootstrap()` initializes Flutter bindings, loads `.env`, initializes Supabase, and starts the app inside `ProviderScope`.
3. `HydrofixApp` applies `HydroTheme.light` and opens `HydroWelcome`.
4. User navigation uses `Navigator` and `MaterialPageRoute`; the project currently does not start through `app_router.dart` or `go_router`.

## Main implementation areas

### Active monolithic UI

`lib/features/stitch_ui/hydrofix_stitch_screens.dart` (3177 lines) contains most of the currently connected UI and behavior:

- `HydroWelcome`, `LoginTypeScreen`, `HydroSignIn`, and `HydroSignUp`
- `HydroShell` and its citizen navigation
- `CitizenHome`, `ReportScreen`, `TrackScreen`, `ProfileScreen`, and notifications
- `ProfessionalDashboardPreview`
- `BmcDashboardPreview`
- Shared screen helpers such as `HydroCard`, `_SectionTitle`, `_Metric`, and `_SeverityTile`

This file mixes presentation and Supabase access. It is the implementation surface that currently determines end-user behavior.

### Theme

`lib/core/theme/hydrofix_theme.dart` defines the HydroFix Material 3 palette and component defaults:

- Teal primary action color
- Navy heading color
- Muted supporting text
- Aqua soft backgrounds
- Green, yellow, and red severity colors
- Rounded cards, inputs, and filled buttons

`lib/app.dart` is the top-level `MaterialApp` configuration and currently sets `HydroWelcome` as the home screen.

### Authentication

`HydroSignIn.submit()` performs a complete role gate:

1. Signs in with Supabase Auth.
2. Loads `profiles.role` and `profiles.is_active`.
3. Rejects mismatched roles and inactive accounts.
4. For professionals, checks `professional_profiles.verification_status == approved`.
5. For BMC users, loads `admin_profiles` and confirms that an officer profile exists.
6. Removes the prior navigation stack and opens the role dashboard.

On authentication or authorization failure, the implementation signs out the current Supabase session and shows an error.

`HydroSignUp.register()` creates a Supabase Auth account and supplies:

- `full_name`
- `phone`
- `role`
- `specialization` for professional registrations

Citizen and professional registration are supported. BMC registration is not exposed.

## Supabase integration

### Initialization

`bootstrap.dart` initializes Supabase from a hard-coded project URL plus `Env.supabasePublishableKey` loaded from `.env`.

`lib/core/config/env.dart` supports these environment names:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Important: bootstrap currently does not read `SUPABASE_URL` from `Env.supabaseUrl`; it should only be changed to environment-driven configuration deliberately and consistently.

Create a local `.env` from `.env.example`, but do not commit real credentials. `.env` is an asset used by the app and must remain available when running.

### Tables used by the active UI

The active implementation directly reads and writes these Supabase tables:

| Table | Primary use |
|---|---|
| `profiles` | Role and active status |
| `admin_profiles` | BMC officer and ward assignment |
| `wards` | Ward name lookup |
| `professional_profiles` | Professional verification, specialization, ward, and availability |
| `complaints` | Complaint title, description, severity, status, location, ward, and assignment |
| `complaint_images` | Storage path metadata for complaint photos |
| `jobs` | Professional assignment and job lifecycle |

The storage bucket `complaint-images` stores before/after complaint images. Citizen report uploads use:

```text
{auth.uid()}/{complaint-id}/before.{jpg|png|webp}
```

Database defaults are expected to generate complaint IDs, tracking IDs, status values, reporter references, and timestamps.

### Supabase RPC functions

The active UI calls:

| RPC | Purpose |
|---|---|
| `review_professional` | Approve or reject a professional application |
| `assign_job` | Assign a complaint to an approved professional |
| `update_my_job` | Change a professional's job status |

The Flutter code does not replace server-side authorization or business validation. BMC/professional actions are intended to be protected by Supabase RLS policies and database functions.

### Edge function

`ReportScreen.verifySeverity()` invokes the `verify-severity` Supabase Edge Function. The request can include:

- `description`
- `imageBase64`
- `imageMimeType`

The function response supplies one of `green`, `yellow`, or `red`, plus optional reason and confidence fields. The citizen can override the recommendation before submission.

Severity mapping:

| UI value | PostgreSQL/UI database value |
|---|---|
| Green | `low` |
| Yellow | `medium` |
| Red | `emergency` |

The BMC dashboard also recognizes `high` as an existing urgent severity value.

## Citizen complaint flow

1. Validate the form.
2. Confirm that a Supabase Auth user exists.
3. Insert a row into `complaints`.
4. Use the returned complaint ID and tracking ID.
5. Optionally resize/compress the photo to at most 1280 px with 65% quality.
6. Reject uploads larger than 4 MB.
7. Upload to `complaint-images`.
8. Insert storage metadata into `complaint_images`.
9. Switch to the track tab after a successful submission.

If complaint insertion succeeds but photo upload fails, the app retains the complaint and reports the partial success. It does not retry the complaint insert.

`TrackScreen` loads up to 50 complaints for `reported_by == currentUser.id`, newest first.

## Professional job flow

The professional dashboard loads approved professional metadata and assigned `jobs`, then attaches the related complaint to each job.

The UI exposes status transitions through `update_my_job`:

```text
offered -> accepted -> on_the_way -> in_progress -> completed
offered -> rejected
```

Job cards display the tracking ID, severity, address, status, estimated duration, and optional description. The RPC remains responsible for enforcing allowed transitions and ownership.

## BMC dashboard flow

The BMC dashboard derives the officer's ward from `admin_profiles`, then loads:

- Complaints in that ward
- Pending professional applications in that ward
- Approved professionals eligible for assignment

It provides:

- Professional approval/rejection
- Complaint-to-professional assignment
- Green, yellow, and red complaint counters

The UI should be treated as presentation over server-side ward and role authorization. Client checks such as `userRole != bmc_admin` are not substitutes for RLS/RPC enforcement.

## Folder layout

The repository contains feature-oriented directories that are not all part of the active runtime path:

- `lib/features/auth/` - alternate auth repository and presentation sources
- `lib/features/admin_portal/` - admin-oriented screens
- `lib/features/user_portal/` - user-oriented feature folders
- `lib/features/professional_shared/` - professional providers and screens
- `lib/features/plumber_portal/` - plumber shell
- `lib/features/electrician_portal/` - electrician shell
- `lib/features/iot/` - MQTT/sensor models and services
- `lib/features/ai_classification/` - separate classifier model and presentation code
- `lib/shared/` - models, repositories, providers, and widgets
- `lib/core/` - environment, networking, routing, theme, services, and utilities
- `test/` - currently sparse placeholder/widget-test coverage

Because these surfaces are not all wired into `HydrofixApp`, a screen existing under `lib/features/` does not prove that it is reachable in the current app.

## Dependencies and platform services

The package manifest includes:

- Supabase, Dio, and Riverpod
- GoRouter
- Firebase Core/Messaging
- Local notifications
- Secure/shared storage
- Image picker
- Geolocator and Google Maps
- Connectivity and permission handling
- Localization and internationalization
- SVG, Lottie, and cached-network-image support

Before relying on a package-specific feature, check the implementation and platform configuration. Several dependencies are present in the manifest or generated platform folders but are not used by the active 3177-line screen implementation.

## Setup

Requirements:

- Flutter with the Dart SDK constraint from `pubspec.yaml`
- A configured Supabase project
- A local `.env` file
- Platform-specific permissions where camera, photo, location, maps, or notifications are used

Typical commands:

```powershell
flutter pub get
flutter analyze
flutter run
```

Run a supported target with, for example:

```powershell
flutter run -d windows
flutter run -d chrome
flutter run -d android
```

Android configuration is present in `android/`; iOS, macOS, web, Windows, and Linux runner directories are also included.

## Testing

The current test suite is mostly placeholder coverage.

`test/widget_test.dart` pumps `HydrofixApp` and expects text `Welcome to Hydrofix`, but the active app opens `HydroWelcome` and renders `Report. Resolve. Conserve.` plus `Get Started`. This test is stale and should be updated before relying on `flutter test`.

Recommended high-value tests:

- Welcome and role-selection navigation
- Citizen login role mismatch and inactive-account behavior
- Professional and BMC account gate behavior
- Severity mapping and Edge Function response handling
- Complaint submission success and photo-upload partial failure
- Complaint refresh and empty/error states
- Professional job status transitions
- BMC ward filtering, professional review, and job assignment
- Supabase mock/repository boundaries instead of direct client calls in widgets

## Known architectural constraints

- `HydrofixApp` bypasses `go_router` and `app_router.dart`; navigation is imperative `Navigator.push`/`pushAndRemoveUntil` code.
- Most active behavior is in one large Dart file instead of the feature, domain, data, and provider structure suggested by `lib/features/`.
- Supabase SDK calls are embedded in widgets, including auth, tables, storage, RPCs, and Edge Functions.
- `lib/core/config/env.dart` has URL support, but bootstrap uses a hard-coded URL and loads only the publishable key from environment configuration.
- `pubspec.yaml` uses unresolved `material_ui: any` and `cupertino_ui: any` dependencies; pinning and dependency review are recommended.
- `HydroShell` is an `IndexedStack` with an in-memory tab index and does not use a route path.
- Tests and localization are not yet connected to the active role flows.
- Platform integration folders contain generated files and build output; source changes should be made in Dart and Android/iOS configuration source directories rather than in `build/`.
