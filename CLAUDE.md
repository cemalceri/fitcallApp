# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"fitcall" is the Binay Akademi mobile app (Flutter) for a sports academy. It serves three user roles — üye (member), antrenör (trainer), and yönetici (manager) — against a REST backend at `https://www.binay.fit/api`. The entire codebase (identifiers, comments, UI text) is in Turkish; follow that convention in new code.

## Commands

```powershell
flutter pub get          # install dependencies
flutter analyze          # lint (flutter_lints, default ruleset)
flutter test             # run tests
flutter test test/widget_test.dart   # run a single test file
flutter run              # run the app (needs a device/emulator)
flutter build apk        # Android release build
```

Release builds are done on Codemagic. Bump `version:` in [pubspec.yaml](pubspec.yaml) for releases.

## Backend Configuration

All API endpoint URLs live in [lib/common/api_urls.dart](lib/common/api_urls.dart), grouped by domain. `baseUrl` is switched manually between prod (`https://www.binay.fit/api`) and local (`http://10.0.2.2:8000/api` — Android emulator loopback) by commenting/uncommenting at the top of that file. New endpoints are added there as top-level string variables.

## Architecture

`lib/` is organized into four layers, with `models/`, `screens/`, and `services/` each subdivided by domain. Models and screens use numbered domain folders (`1_common`, `2_uye`, `3_antrenor`, `4_auth`, `5_etkinlik` (lessons/events), `6_muhasebe` (accounting), `7_kort` (courts), `8_urun` (products), `9_yonetici`); services use unnumbered domain folders plus `services/core/` for cross-cutting concerns (auth, secure storage, FCM, app update).

### API layer

- [lib/services/api_client.dart](lib/services/api_client.dart) — static `ApiClient`. New code should use `postParsed<T>`/`getParsed<T>`, which take a `fromJson` callback and return `ApiResult<T>` (`{mesaj, data}`). Pass `auth: true` to attach the Bearer token from secure storage. Errors are thrown as `ApiException(code, message, statusCode)`; the backend's own `message`/`detail` field is preferred for display. `postJson`/`getJson` are legacy low-level variants.
- Services are classes with static methods (e.g. `AuthService`) that call `ApiClient` with URLs from `api_urls.dart` and parse into models via `ApiParsing.parseObject`/`parseList` ([lib/services/api_result.dart](lib/services/api_result.dart)).
- Models are hand-written `fromJson`/`toJson` classes (no codegen).

### Auth, roles, and routing

- Roles are the `Roller` enum in [lib/common/constants.dart](lib/common/constants.dart): `yonetici`, `uye`, `antrenor`, `cafe`.
- Login flow: `AuthService.fetchMyMembers` returns the user's profiles (one account can have multiple member/trainer profiles); the user picks one in `profil_sec.dart`, then `AuthService.loginUser` requests a role-scoped token (`createToken`) and stores everything in `flutter_secure_storage` via `StorageService`/`SecureStorageService` ([lib/services/core/storage_service.dart](lib/services/core/storage_service.dart)).
- All navigation is named-route based through [lib/common/routes.dart](lib/common/routes.dart): the `SayfaAdi` enum maps to route strings (`routeEnums`), which map to widget builders (`routes`). `myRouteGenerator` (wired as `onGenerateRoute` in `main.dart`) is the auth guard: routes not in `publicRoutes` check token validity (`StorageService.tokenGecerliMi`) and redirect to login, and routes marked `AccessRule.anaHesapOnly` in `accessPolicies` additionally require the active profile to be the "ana hesap" (primary account). To add a screen: add a `SayfaAdi` value, a route string, a builder, and an access policy entry if it needs the ana-hesap guard.

### Notifications

Firebase Cloud Messaging. `main.dart` initializes Firebase + `NotificationFCMService` and exposes a global `navigatorKey` so notification taps can navigate (deep-link pages live in `lib/screens/1_common/1_notification/pages/`). FCM token registration/refresh is handled by `initFCMTokenListener` in [lib/services/core/fcm_service.dart](lib/services/core/fcm_service.dart).

### Screens

Page widgets live at the domain folder root; their subcomponents go in a sibling `widgets/` folder. Shared UI helpers (snackbar/message display, spinners, KVKK text) are in `lib/screens/1_common/widgets/`. The üye and antrenör calendars (`takvim/`) are parallel implementations with their own `timeline_view`, `lesson_block`, and `position_calculator` widgets — changes to one calendar often need mirroring in the other.
