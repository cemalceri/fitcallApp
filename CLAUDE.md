# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"fitcall" is the Binay Akademi mobile app (Flutter) for a sports academy. It serves three user roles — üye (member), antrenör (trainer), and yönetici (manager) — against a REST backend at `https://www.binay.fit/api`. The entire codebase (identifiers, comments, UI text) is in Turkish; follow that convention in new code.

## Documentation map

Read by need, not all at once — only `CLAUDE.md` is loaded automatically.

| File | Read it when |
|---|---|
| [MOBIL_GELISTIRMELER.md](MOBIL_GELISTIRMELER.md) | **Start of any feature or planning session.** The single status doc: current state (version, test count, what's deployed), open items, the next-phase backlog, and an archive of solved critical bugs. Update it when a round of work lands or an item is closed — do not create a second "pending work" file. |
| [SURUM_NOTLARI.md](SURUM_NOTLARI.md) | Cutting a release. Store "what's new" text (**tr-TR only** — an en-US listing would oblige us to supply English screenshots and metadata to Apple) plus a technical summary, newest first. Add a section whenever `version:` in `pubspec.yaml` is bumped. |
| [CODEMAGIC_KURULUM.md](CODEMAGIC_KURULUM.md) | Touching `codemagic.yaml` or the release pipeline. One-time setup of Play/App Store credentials, keystore, webhook. |

`README.md` is unmodified Flutter boilerplate — ignore it.

### Backend repo

The Django backend lives at `C:\Django\tenis` (branch `master`, deployed to Heroku). Two of its docs matter for mobile work:

- `history.md` — dated changelog (problem → solution, newest first) covering **both** repos. Read it for historical context instead of digging through git log; append a short entry there after a significant cross-cutting change.
- `MODEL_ILISKILERI.md` — every model, its FKs, unique constraints, and key flows. Read before any task that reasons about backend data relationships.

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

### Date/time contract

[lib/common/tarih_util.dart](lib/common/tarih_util.dart) is the single entry point for API date handling; backend counterpart is `calendarapp/utils/tarih_util.py`.

- **Reading:** always `parseApiTarih(...)` (or `parseApiTarihOrNow` / `parseApiGun`), never raw `DateTime.parse`. The server sends local time with an offset (`"2026-07-23T10:00:00+03:00"`); Dart's `DateTime.parse` converts that to a UTC `DateTime`, so `.hour` and `DateFormat` would read 3 hours early. The helper applies `.toLocal()`.
- **Writing:** always `formatApiTarih(...)` → offset-less local ISO (`"2026-07-23T10:00:00"`), which the backend interprets as Istanbul. Never send `.toUtc()`/`Z`.

### Yönetici ders yönetimi

`lib/screens/7_yonetici/program/` is the mobile counterpart of the web `/etkinlik-pilot` screen: day strip plus a horizontally scrollable court × hour grid, with create/edit/cancel/delete. It talks to `yoneticiHaftalikProgram` / `yoneticiEtkinlik*` through [yonetici_etkinlik_service.dart](lib/services/yonetici/yonetici_etkinlik_service.dart). Save and cancel run through shared backend services, so rules match the web exactly — validate there, not here.

### Layout / overflow discipline

App-wide text scale is clamped to `[1.0, 1.3]` ([lib/common/ui_scale.dart](lib/common/ui_scale.dart), wired via `MaterialApp.builder` in `main.dart`) so accessibility "huge font" (up to 2.0x) can't blow up dense layouts. New screens must not overflow within that range. [test/support/tasma_yardimcisi.dart](test/support/tasma_yardimcisi.dart) provides `tasmaTesti(...)` which renders a widget across a screen-size × text-scale matrix and fails on any RenderFlex overflow; [test/tasma_ekranlar_test.dart](test/tasma_ekranlar_test.dart) covers the yönetici/antrenör/üye components. Add every new presentational widget there. Because pages call APIs in `initState` they can't be pumped directly — extract the visual body into a data-fed widget (as `program/widgets/program_gorunumu.dart` does for the program page) so it's testable.

### Screens

Page widgets live at the domain folder root; their subcomponents go in a sibling `widgets/` folder. Shared UI helpers (snackbar/message display, spinners, KVKK text) are in `lib/screens/1_common/widgets/`. The üye and antrenör calendars (`takvim/`) are parallel implementations with their own `timeline_view`, `lesson_block`, and `position_calculator` widgets — changes to one calendar often need mirroring in the other.
