# Whitelabel

Whitelabel builds of Fluxer Mobile (Oxygen) for Die Linke (`pdl`) and Linksjugend ['solid] (`ljs`).

```bash
./whitelabel/build.sh pdl          # APK
./whitelabel/build.sh ljs appbundle
```

`<ctx>.json` is passed as `--dart-define-from-file`:

| Key | Purpose |
|---|---|
| `FLUXER_APP_ID` | Android application id (`de.dielinke.meine.<ctx>`) |
| `FLUXER_APP_NAME` | Name on the home screen |
| `FLUXER_DEFAULT_INSTANCE`, `..._API_BASE_URL`, `..._GATEWAY_URL` | Instance the app talks to |
| `FLUXER_LOCK_INSTANCE` | Hide the instance selector |
| `PUSH_PROVIDER` | `unifiedpush` (no Firebase) |
| `OBSERVABILITY_REPORTING` | Off: no crash/telemetry reporting to Fluxer |

The in-app product name and branding come from the instance (`branding.product_name`).

## Branches

- `upstream`: raw upstream (`fluxer/canary`)
- `contributions`: generic changes meant to be upstreamed (DCO sign-off, `git commit -s`)
- `trunk`: whitelabel, merges `contributions`

## TODO

- Icons and splash per context
- iOS bundle id / display name (`FLUXER_APP_ID` is Android only so far)
- Instance: stage (`fluxer.aprl2.bak-it-stage.de`) until production exists
