# Whitelabel

Whitelabel builds of Fluxer Mobile (Oxygen) for Die Linke (`pdl`) and Linksjugend ['solid] (`ljs`).

```bash
./whitelabel/build.sh pdl          # APK
./whitelabel/build.sh ljs appbundle
```

`build.sh` runs `apply.sh <ctx>` first, which patches the working tree (icons, splash, colours, iOS bundle ids,
app group, display names). Use a clean checkout per context.

## Files

- `<ctx>.json`: passed as `--dart-define-from-file`

  | Key | Purpose |
  |---|---|
  | `FLUXER_APP_ID` | Android application id / iOS bundle id prefix (`de.dielinke.meine.<ctx>`) |
  | `FLUXER_APP_NAME` | Name on the home screen |
  | `FLUXER_DEFAULT_INSTANCE`, `..._API_BASE_URL`, `..._GATEWAY_URL` | Instance the app talks to |
  | `FLUXER_LOCK_INSTANCE` | Hide the instance selector |
  | `PUSH_PROVIDER` | `unifiedpush` (no Firebase) |
  | `OBSERVABILITY_REPORTING` | Off: no crash/telemetry reporting to Fluxer |

- `brand/<ctx>/mark.svg`, `brand.json`: logo (white) and brand colour
  - pdl: https://meine.die-linke.de/static/assets/icons/logo.svg
  - ljs: https://login.linksjugend-solid.de/static/assets/icons/logo.svg
- `brand/<ctx>/generated/`: icons and splash, regenerate after changing the logo or colour:
  `nix-shell -p librsvg imagemagick python3 --run 'python3 whitelabel/tools/generate_assets.py'`
- `fonts/<font>/`: UI font replacing IBM Plex Sans if `brand.json` sets `font`, SIL OFL 1.1
  - pdl: Inter (rsms/inter v4.1), body font of lissi.die-linke.de
  - ljs: keeps IBM Plex Sans
  - `heading_font`: Work Sans (static instances, Latin subset) for the `heading` text style, -0.02em letter spacing
    (lissi.die-linke.de headline font; LJS uses Gilroy, which is proprietary)

Colours: the app takes the instance's `theme_color` as brand colour (`contributions`, like the web app does on
self-hosted instances), unless the user set an own accent.

The in-app product name and branding come from the instance (`branding.product_name`).

## CI

`.gitlab-ci.yml` builds one APK per ABI (arm64-v8a, armeabi-v7a) on `trunk` and uploads them to the
package registry (`meine-<ctx>-android/<pipeline>/`), as they are too large for job artifacts.
No CI cache: the runners' cache URL is misconfigured (`https://https://...`). Optional CI variables for release signing:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
(otherwise the debug key is used; the release key must never change once published).

iOS builds on GitHub Actions (free macOS runners for public repositories) in the public fork
[aprilthepink/meine-chat-oxygen](https://github.com/aprilthepink/meine-chat-oxygen), workflow
`.github/workflows/whitelabel-ios.yml`: `whitelabel/build.sh <ctx> ios` with `--no-codesign`, an unsigned IPA per
context as workflow artifact. An iPhone only runs it re-signed (Sideloadly/AltStore with an own Apple ID, 7 days);
TestFlight/App Store need an Apple Developer account: `APPLE_TEAM_ID=… whitelabel/build.sh <ctx> ipa` with the
certificate and provisioning profiles (app, ShareExtension, NotificationService, BroadcastExtension, app group
`group.<FLUXER_APP_ID>`) in the keychain.

## Branches

- `upstream`: raw upstream (`fluxer/canary`)
- `contributions`: generic changes meant to be upstreamed (sign off with `git rebase --signoff upstream` before submitting)
- `trunk`: whitelabel, merges `contributions`

## TODO

- Alternative app icons (Fluxer icon picker) still show Fluxer icons
- Push (UnifiedPush distributor / APNs for iOS)
- Instance: stage (`fluxer.aprl2.bak-it-stage.de`) until production exists
