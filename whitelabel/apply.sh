#!/usr/bin/env bash
# Usage: whitelabel/apply.sh <pdl|ljs>  (patches the working tree; APPLE_TEAM_ID optional)
set -euo pipefail

ctx="${1:?usage: $0 <pdl|ljs>}"
cd "$(dirname "$0")/.."

config="whitelabel/$ctx.json"
brand="whitelabel/brand/$ctx"
gen="$brand/generated"
marker="build/.whitelabel-applied"
[[ -f "$config" && -d "$gen" ]] || { echo "unknown context: $ctx" >&2; exit 1; }

if [[ -f "$marker" ]]; then
  [[ "$(cat "$marker")" == "$ctx" ]] && { echo "whitelabel $ctx already applied"; exit 0; }
  echo "whitelabel $(cat "$marker") already applied, reset the checkout first" >&2
  exit 1
fi

json() { sed -nE "s/.*\"$1\": *\"([^\"]*)\".*/\1/p" "$2" | head -n1; }
app_id="$(json FLUXER_APP_ID "$config")"
app_name="$(json FLUXER_APP_NAME "$config")"
instance="$(json FLUXER_DEFAULT_INSTANCE "$config")"
color="$(json color "$brand/brand.json")"
for var in app_id app_name instance color; do
  [[ -n "${!var}" ]] || { echo "missing $var for $ctx" >&2; exit 1; }
done

replace() {
  local file="$1" pattern="$2" replacement="$3"
  grep -qE "$pattern" "$file" || { echo "apply.sh: '$pattern' not found in $file" >&2; exit 1; }
  sed -i.bak -E "s~$pattern~$replacement~g" "$file"
  rm -f "$file.bak"
}

res=android/app/src/main/res
cp -R "$gen/android/res/." "$res/"
replace "$res/values/colors.xml" '(<color name="launch_background">)[^<]*' "\1$color"
replace "$res/values/ic_launcher_background.xml" '(<color name="ic_launcher_background">)[^<]*' "\1$color"

rm -rf ios/Runner/AppIcon.icon
cp -R "$gen/ios/AppIcon.icon" ios/Runner/
cp -R "$gen/ios/WLSplash.imageset" ios/Runner/Assets.xcassets/
cp "$gen/ios/LaunchScreen.storyboard" ios/Runner/Base.lproj/LaunchScreen.storyboard

pbx=ios/Runner.xcodeproj/project.pbxproj
replace "$pbx" 'PRODUCT_BUNDLE_IDENTIFIER = com\.fluxer([.;])' "PRODUCT_BUNDLE_IDENTIFIER = $app_id\1"
replace "$pbx" 'INFOPLIST_KEY_CFBundleDisplayName = "?Fluxer( Canary| Beta)?"?;' "INFOPLIST_KEY_CFBundleDisplayName = \"$app_name\1\";"
replace "$pbx" 'INFOPLIST_KEY_CFBundleDisplayName = "Share to Fluxer";' "INFOPLIST_KEY_CFBundleDisplayName = \"$app_name\";"
replace "$pbx" 'INFOPLIST_KEY_CFBundleDisplayName = "Fluxer Screen Share";' "INFOPLIST_KEY_CFBundleDisplayName = \"$app_name Bildschirm\";"
replace "$pbx" 'DEVELOPMENT_TEAM = 3G5837T29K;' "DEVELOPMENT_TEAM = \"${APPLE_TEAM_ID:-}\";"

group_files="$(grep -rlE 'group\.com\.fluxer' ios --exclude-dir=Pods || true)"
[[ -n "$group_files" ]] || { echo "apply.sh: no app group references found" >&2; exit 1; }
for file in $group_files; do
  replace "$file" 'group\.com\.fluxer' "group.$app_id"
done
replace ios/Runner/Runner.entitlements '\$\(AppIdentifierPrefix\)com\.fluxer' "\$(AppIdentifierPrefix)$app_id"
perl -0pi -e "s#(<key>com.apple.developer.associated-domains</key>\s*<array>).*?(</array>)#\$1\n\t\t<string>applinks:$instance</string>\n\t\t<string>webcredentials:$instance</string>\n\t\$2#s" ios/Runner/Runner.entitlements

if grep -qE 'PRODUCT_BUNDLE_IDENTIFIER = com\.fluxer|group\.com\.fluxer|(applinks|webcredentials):(canary\.|web\.)?fluxer\.(com|app|gg)' "$pbx" ios/Runner/Runner.entitlements; then
  echo "apply.sh: Fluxer identifiers left after rebranding" >&2
  exit 1
fi

mkdir -p build
echo "$ctx" > "$marker"
echo "whitelabel $ctx applied"
