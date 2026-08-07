# TOKEN

TOKEN is a personal resource management application that interprets real KRW as finite internal resources rather than merely showing spending history.

## Current development status

Initial Flutter skeleton + TOKEN Core decimal rules.

Implemented:
- TOKEN fixed-point amount (scale=2)
- Negative TOKEN support
- KRW -> TOKEN HALF_UP conversion
- No binary floating point in TOKEN conversion
- Transaction model with frozen `appliedExchangeRate`
- Display-only trailing-zero removal
- Core unit tests
- GitHub Actions automatic Android debug APK build

## Important core rules

- TOKEN is not real money.
- TOKEN balances may go below zero.
- Spending must not be blocked due to insufficient TOKEN.
- Historical transaction exchange rates are frozen per transaction.
- TOKEN values use fixed-point scale=2.
- `double`, `float`, binary floating point and `floor()` must not be used for TOKEN amount calculations.

## Upload from Android

1. Open the `Seolhwa001/Token` repository in GitHub.
2. Choose **Add file -> Upload files**.
3. Extract this project ZIP on your Android device first.
4. Upload the **contents inside the extracted folder**, not the ZIP itself.
5. Commit directly to `main`.

Important: `.github/workflows/android-apk.yml` must be uploaded too.

## Build APK on GitHub

Every push to `main` starts the workflow automatically.

GitHub mobile/web:
1. Open repository.
2. Open **Actions**.
3. Select **Build Android APK**.
4. Wait until the run becomes green.
5. Open the completed run.
6. Under **Artifacts**, download `TOKEN-debug-apk`.
7. Extract the artifact ZIP and install `app-debug.apk` on Android.

You may also open **Actions -> Build Android APK -> Run workflow** to build manually.

## Notes

The repository intentionally does not include generated Android platform files yet. GitHub Actions generates a temporary Flutter Android project and copies only its `android/` platform directory into the build workspace. Your TOKEN Dart source files are not overwritten.

This keeps the initial Android upload small and makes it possible to bootstrap the project without a local Flutter SDK.
