# 1-Hour Inactivity Auto-Logout — Design

Date: 2026-07-21
Status: Approved, ready for implementation plan

## Context

The app currently has no inactivity timeout: once logged in, a session stays
usable until the access token's fixed 4-hour server-side expiry, regardless of
whether the user is actively using the app. Manual logout exists
([user_navigation.dart:82-98](../../../lib/popup/user_navigation.dart)) and does
real server-side work (revokes the user's token, disconnects the chat
WebSocket, flips `account_status` to `LOGGED_OUT`).

Backend research findings that shaped this design (see conversation history for
full detail):
- Access tokens are JWTs with a hardcoded, non-configurable 4h expiry
  (`JwtConstants.java`).
- `refreshToken` is generated at login but never persisted or redeemable — no
  `/refresh` endpoint exists anywhere (Java controllers or OpenAPI spec).
- There is no server-side idle-tracking mechanism at all: no Redis, no
  timestamp column on the `token` table, no sliding-expiration logic in
  `JwtAuthenticationFilter` or the WebSocket handshake interceptor.
- Login already revokes all previous tokens for a user, i.e. the backend
  already assumes a single active session per user — a client-only idle
  logout that calls the real logout endpoint doesn't introduce any new
  multi-tab/multi-device conflict beyond what already exists today.

## Decision: client-only enforcement

This feature is enforced entirely in the Flutter frontend. No backend changes.
The tradeoff (explicitly accepted): a copied/replayed JWT remains valid
server-side for the rest of its 4h life even if the original client
auto-logs-out from inactivity. Server-enforced idle timeout (DB migration +
filter changes) was considered and explicitly deferred — out of scope for this
spec.

## Requirements (from clarifying questions)

1. Idle threshold: **1 hour** of no user activity.
2. Activity signal: **any UI interaction** (pointer/tap/drag/scroll or key
   press) anywhere in the app. Background API/WebSocket traffic does **not**
   count as activity.
3. On firing: perform the **same logout sequence as the manual logout
   button** — call the logout API (best-effort), disconnect the WebSocket,
   clear the cached user, navigate to `/login`.
4. UX: show a **warning dialog 60 seconds before** the actual logout, giving
   the user a chance to stay logged in with one tap. Interacting with the
   warning counts as activity like anything else.

## Architecture

### `IdleTimerService`
New singleton, registered in GetIt at app startup (`main.dart`), alongside
`WebSocketService` etc. Lives for the app's lifetime; does not need explicit
start/stop wiring at every login/logout call site.

- Constants: `idleDuration = Duration(hours: 1)`,
  `warningLeadTime = Duration(seconds: 60)` (overridable in debug builds for
  QA — see Testing).
- `recordActivity()`: cancels any pending timers, records
  `DateTime.now()` as `_lastActivity`, and (only if
  `getIt<User>().username.isNotEmpty`) schedules a single `Timer` for
  `idleDuration - warningLeadTime`.
- When that timer fires: shows the warning dialog and starts a second
  `Timer` for `warningLeadTime`.
- If the second timer fires: calls `AuthService.logout()`.
- If `recordActivity()` is called at any point (including a tap on the
  warning dialog's "stay logged in" button), both pending timers are
  cancelled and rescheduled from zero — the dialog is also dismissed.
- If not logged in, `recordActivity()` still records the timestamp but does
  not schedule anything (no-op session).

### Root-level activity detector
A new widget wraps `MaterialApp.router` inside `_MyAppState.build` in
`main.dart`:
- `Listener` (`onPointerDown`/`onPointerMove`/`onPointerSignal`) at the top
  of the tree — pointer events bubble through it regardless of which screen
  is active, covering taps, drags, and scroll-wheel input.
- `KeyboardListener` (or `HardwareKeyboard.instance.addHandler`) for key
  events, so keyboard-only interaction also counts.
- Both call `getIt<IdleTimerService>().recordActivity()`.

This is a single integration point — no per-page changes needed.

### `AuthService.logout()` (extracted, shared)
The inline logout logic currently in the "Logout" button's `onPressed`
([user_navigation.dart:82-98](../../../lib/popup/user_navigation.dart)) moves
into a shared function:
1. `try { await getIt<UserDao>().logout(LogoutRequest(userId: getIt<User>().id)); } catch (_) {}`
   — best-effort; a network failure must not block local cleanup.
2. `getIt<WebSocketService>().disconnect()`.
3. Reset `getIt<User>()` to the empty placeholder (same pattern already used
   in `user_navigation.dart` and `main.dart`).
4. Navigate via `AppRouter.router.go(AppRouter.loginPath)` — this is a
   `GoRouter` instance method that needs no `BuildContext`, so it's callable
   from a service, not just from a widget's button handler.

Both the manual "Logout" button and `IdleTimerService`'s logout path call this
one function, so they cannot drift apart in behavior.

The warning dialog (shown before logout, not part of `AuthService.logout()`
itself) does need a `BuildContext` to call `showDialog`, obtained via
`AppRouter.router.routerDelegate.navigatorKey.currentContext`.

### Backgrounding / throttled timers
Browser tabs (and some mobile OS states) can throttle `Timer`s while
backgrounded, so a `Timer` alone might fire late or not at all while hidden.
`IdleTimerService` also implements `WidgetsBindingObserver` and, on
`didChangeAppLifecycleState(AppLifecycleState.resumed)`, compares
`DateTime.now()` against the stored `_lastActivity` timestamp; if it already
exceeds `idleDuration`, it triggers logout immediately instead of waiting for
a possibly-delayed timer to fire.

## Error handling

- Logout API call failure during idle-triggered logout: swallowed (matches
  existing manual-logout behavior) — local session cleanup and navigation to
  `/login` proceed regardless, since the goal is client-side session
  termination even if the network is unreachable.
- If the warning dialog is already showing and the resume-from-background
  check independently determines logout should happen, the dialog is
  dismissed and logout proceeds (no double-navigation).
- If `AppRouter.router.routerDelegate.navigatorKey.currentContext` is null
  when trying to show the warning dialog (e.g. mid-teardown), the warning is
  skipped and the logout timer still runs to completion — the existing
  router `redirect` (which already checks `getIt<User>().username != ''`)
  will bounce the user to `/login` on the next navigation attempt regardless.

## Testing

- `test/widget_test.dart` is already broken for unrelated reasons (confirmed
  pre-existing: a `package:web`/JS-interop SDK version mismatch unrelated to
  this feature), so it isn't a reliable regression signal today and this
  feature doesn't depend on fixing it.
- Add a focused unit test for `IdleTimerService`'s scheduling logic (activity
  resets timers; warning fires at the right offset; logout fires after the
  warning; resume-from-background catches an overdue idle period) using
  `package:fake_async` (new dev dependency).
- Manual QA: gate a debug-only override of `idleDuration`/`warningLeadTime`
  behind `kDebugMode` (e.g. 10s idle / 3s warning) so the full flow can be
  exercised in seconds without changing production behavior.
- Verify via `flutter analyze` and a `flutter build web` after implementation,
  consistent with how prior changes in this project were verified.

## Out of scope (explicitly deferred)

- Server-enforced idle timeout (DB migration, `JwtAuthenticationFilter` /
  `AuthHandshakeInterceptor` changes) — noted as a possible follow-up if a
  stronger security guarantee is wanted later.
- Fixing the pre-existing `widget_test.dart` JS-interop failure.
- The WebSocket handshake's insecure `?userId=` fallback (no-token path)
  found during backend research — flagged separately, unrelated to idle
  logout.
