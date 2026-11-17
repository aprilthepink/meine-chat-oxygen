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
- `fonts/<font>/`: UI font replacing IBM Plex Sans (`brand.json` `font`), SIL OFL 1.1
  - pdl: Inter (rsms/inter v4.1), body font of lissi.die-linke.de
  - ljs: Hind (google/fonts), Latin subset, no italic (Flutter slants it)

The in-app product name and branding come from the instance (`branding.product_name`).

## CI

`.gitlab-ci.yml` builds one APK per ABI (arm64-v8a, armeabi-v7a) on `trunk` and uploads them to the
package registry (`meine-<ctx>-android/<pipeline>/`), as they are too large for job artifacts.
No CI cache: the runners' cache URL is misconfigured (`https://https://...`). Optional CI variables for release signing:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
(otherwise the debug key is used; the release key must never change once published).

iOS needs a macOS runner and an Apple team: `APPLE_TEAM_ID=… whitelabel/apply.sh <ctx>`, then
`flutter build ipa --flavor stable --dart-define-from-file=tool/dart_defines/stable.json --dart-define-from-file=whitelabel/<ctx>.json`.

## Branches

- `upstream`: raw upstream (`fluxer/canary`)
- `contributions`: generic changes meant to be upstreamed (sign off with `git rebase --signoff upstream` before submitting)
- `trunk`: whitelabel, merges `contributions`

## TODO

- Alternative app icons (Fluxer icon picker) still show Fluxer icons
- Push (UnifiedPush distributor / APNs for iOS)
- Instance: stage (`fluxer.aprl2.bak-it-stage.de`) until production exists
