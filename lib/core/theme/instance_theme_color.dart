import 'dart:math' as math;

import 'package:fluxer_app/core/theme/css_color_parser.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/theme_token_aliases.dart';
import 'package:fluxer_app/core/theme/theme_variable_mapping.dart';
import 'package:fluxer_app/material_ui.dart';

const double _kMinTextContrast = 4.5;
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kBlack = Color(0xFF000000);

final Expando<Map<(String, double), FluxerColorTheme>> _cache =
    Expando<Map<(String, double), FluxerColorTheme>>();

FluxerColorTheme applyInstanceThemeColor(
  FluxerColorTheme base, {
  required String? themeColor,
  required double saturationFactor,
}) {
  final String? hex = themeColor?.trim();
  if (hex == null || hex.isEmpty) {
    return base;
  }
  final Map<(String, double), FluxerColorTheme> cache = _cache[base] ??=
      <(String, double), FluxerColorTheme>{};
  return cache[(hex, saturationFactor)] ??= _applyBrand(
    base,
    hex,
    saturationFactor,
  );
}

FluxerColorTheme _applyBrand(
  FluxerColorTheme base,
  String hex,
  double saturationFactor,
) {
  final Color? parsed = parseCssColor(hex, saturationFactor: saturationFactor);
  if (parsed == null) {
    return base;
  }
  final HSLColor hsl = HSLColor.fromColor(parsed);
  final HSLColor brand = hsl.withSaturation(hsl.saturation * saturationFactor);
  final Color primary = brand.toColor();
  final Color onPrimary = _readableOn(primary);
  final Map<String, Color> overrides = <String, Color>{
    'brandPrimary': primary,
    'brandSecondary': brand
        .withSaturation(brand.saturation * 6 / 7)
        .withLightness(brand.lightness * 0.89)
        .toColor(),
    'brandPrimaryFill': onPrimary,
    'textOnBrandPrimary': onPrimary,
  };
  propagateLinkedThemeProperties(overrides, overrides.keys.toSet());
  return base.applyPropertyOverrides(overrides);
}

Color _readableOn(Color background) {
  final double onWhite = _contrast(_kWhite, background);
  if (onWhite >= _kMinTextContrast ||
      onWhite >= _contrast(_kBlack, background)) {
    return _kWhite;
  }
  return _kBlack;
}

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
