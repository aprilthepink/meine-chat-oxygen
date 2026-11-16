#!/usr/bin/env python3
"""Usage: nix-shell -p librsvg imagemagick python3 --run 'python3 whitelabel/tools/generate_assets.py [ctx...]'"""

import json
import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def run(*args):
    subprocess.run(args, check=True)


def master_png(svg: Path, tmp: Path) -> Path:
    raw, out = tmp / "raw.png", tmp / "master.png"
    run("rsvg-convert", "-w", "4096", str(svg), "-o", str(raw))
    run("magick", str(raw), "-trim", "+repage", str(out))
    return out


def mark_size(master: Path, diagonal: float) -> tuple[int, int]:
    w, h = (int(v) for v in subprocess.check_output(["magick", "identify", "-format", "%w %h", str(master)]).split())
    scale = diagonal / math.hypot(w, h)
    return max(1, round(w * scale)), max(1, round(h * scale))


def compose(master: Path, out: Path, canvas: int, diagonal: float, background: str = "none", shape: str = "square"):
    out.parent.mkdir(parents=True, exist_ok=True)
    w, h = mark_size(master, diagonal)
    args = ["magick", "-size", f"{canvas}x{canvas}", "xc:none"]
    if background != "none":
        if shape == "circle":
            draw = f"circle {canvas / 2},{canvas / 2} {canvas / 2},0"
        else:
            r = canvas * 0.18
            draw = f"roundrectangle 0,0 {canvas - 1},{canvas - 1} {r},{r}"
        args += ["-fill", background, "-draw", draw]
    args += ["(", str(master), "-resize", f"{w}x{h}!", ")", "-gravity", "center", "-composite"]
    args += ["-define", "webp:lossless=true", str(out)]
    run(*args)


def plain(master: Path, out: Path, diagonal: float):
    out.parent.mkdir(parents=True, exist_ok=True)
    w, h = mark_size(master, diagonal)
    run("magick", str(master), "-resize", f"{w}x{h}!", str(out))


def srgb_to_display_p3(hex_color: str) -> str:
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    def enc(c):
        c = min(max(c, 0.0), 1.0)
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

    r, g, b = (lin(int(hex_color[i : i + 2], 16) / 255) for i in (1, 3, 5))
    p3 = (
        0.8224621 * r + 0.1775380 * g,
        0.0331941 * r + 0.9668058 * g,
        0.0170827 * r + 0.0723974 * g + 0.9105199 * b,
    )
    return "display-p3:" + ",".join(f"{enc(c):.5f}" for c in p3) + ",1.00000"


ADAPTIVE_ICON = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/wl_brand"/>
    <foreground android:drawable="@mipmap/wl_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/wl_launcher_foreground"/>
</adaptive-icon>
"""

LAUNCH_BACKGROUND = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/wl_brand"/>
    <item>
        <bitmap android:src="@mipmap/wl_splash" android:gravity="center"/>
    </item>
</layer-list>
"""

BITMAP = """<?xml version="1.0" encoding="utf-8"?>
<bitmap xmlns:android="http://schemas.android.com/apk/res/android"
    android:src="@mipmap/{name}"
    android:gravity="center"/>
"""

COLORS = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="wl_brand">{color}</color>
</resources>
"""

LAUNCH_SCREEN = """<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="24765" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="24743"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView userInteractionEnabled="NO" contentMode="center" image="WLSplash" translatesAutoresizingMaskIntoConstraints="NO" id="wl-sp-img">
                                <rect key="frame" x="96.5" y="376" width="200" height="100"/>
                            </imageView>
                        </subviews>
                        <color key="backgroundColor" red="{r}" green="{g}" blue="{b}" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="wl-sp-img" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="wl-sp-cx"/>
                            <constraint firstItem="wl-sp-img" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="wl-sp-cy"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
    <resources>
        <image name="WLSplash" width="200" height="100"/>
    </resources>
</document>
"""


def generate(ctx: str):
    brand_dir = ROOT / "brand" / ctx
    brand = json.loads((brand_dir / "brand.json").read_text())
    color = brand["color"]
    out = brand_dir / "generated"
    shutil.rmtree(out, ignore_errors=True)
    res = out / "android" / "res"
    ios = out / "ios"

    with tempfile.TemporaryDirectory() as tmp_name:
        master = master_png(brand_dir / "mark.svg", Path(tmp_name))

        for density, f in DENSITIES.items():
            mip = res / f"mipmap-{density}"
            compose(master, mip / "ic_launcher.webp", round(48 * f), 30 * f, color)
            compose(master, mip / "ic_launcher_round.webp", round(48 * f), 30 * f, color, "circle")
            compose(master, mip / "wl_launcher_foreground.png", round(108 * f), 62 * f)
            plain(master, mip / "wl_splash.png", 150 * f)
            compose(master, mip / "wl_splash_icon.png", round(288 * f), 176 * f)
            compose(master, mip / "wl_stat.png", round(24 * f), 22 * f)

        (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
        for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
            (res / "mipmap-anydpi-v26" / name).write_text(ADAPTIVE_ICON)
        (res / "drawable").mkdir(parents=True, exist_ok=True)
        (res / "drawable" / "launch_background.xml").write_text(LAUNCH_BACKGROUND)
        (res / "drawable" / "splash_icon.xml").write_text(BITMAP.format(name="wl_splash_icon"))
        (res / "drawable" / "ic_stat_fluxer.xml").write_text(BITMAP.format(name="wl_stat"))
        (res / "values").mkdir(parents=True, exist_ok=True)
        (res / "values" / "wl_colors.xml").write_text(COLORS.format(color=color))

        icon = ios / "AppIcon.icon"
        (icon / "Assets").mkdir(parents=True)
        plain(master, icon / "Assets" / "Mark.png", 780)
        (icon / "icon.json").write_text(
            json.dumps(
                {
                    "fill": {"solid": srgb_to_display_p3(color)},
                    "groups": [
                        {
                            "layers": [{"fill": "automatic", "image-name": "Mark.png", "name": "Mark"}],
                            "shadow": {"kind": "neutral", "opacity": 0.5},
                            "translucency": {"enabled": False, "value": 0.5},
                        }
                    ],
                    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
                },
                indent=2,
            )
            + "\n"
        )

        splash = ios / "WLSplash.imageset"
        splash.mkdir(parents=True)
        images = []
        for scale in (1, 2, 3):
            name = "WLSplash.png" if scale == 1 else f"WLSplash@{scale}x.png"
            plain(master, splash / name, 200 * scale)
            images.append({"idiom": "universal", "filename": name, "scale": f"{scale}x"})
        (splash / "Contents.json").write_text(
            json.dumps({"images": images, "info": {"version": 1, "author": "xcode"}}, indent=2) + "\n"
        )

        r, g, b = (int(color[i : i + 2], 16) / 255 for i in (1, 3, 5))
        (ios / "LaunchScreen.storyboard").write_text(LAUNCH_SCREEN.format(r=f"{r:.4f}", g=f"{g:.4f}", b=f"{b:.4f}"))
    print(f"generated {out.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    contexts = sys.argv[1:] or sorted(p.name for p in (ROOT / "brand").iterdir() if p.is_dir())
    for ctx in contexts:
        generate(ctx)
