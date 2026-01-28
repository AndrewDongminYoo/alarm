// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 📦 Package imports:
import 'package:json_annotation/json_annotation.dart';

/// {@template color_converter}
/// A [JsonConverter] between Flutter [Color] (ARGB)
/// and web/Figma-style hex strings using `RRGGBBAA` (RGBA) format,
/// optionally prefixed with `#`.
///
/// Supported input formats (with or without leading `#`):
///   - RGB   (3 chars)  -> RRGGBBFF
///   - RGBA  (4 chars)  -> RRGGBBAA
///   - RRGGBB (6 chars) -> RRGGBBFF
///   - RRGGBBAA (8 chars)
///
/// Examples:
///   * Color(0x66FBEA37) (AARRGGBB) ⇔ "#FBEA3766" (RRGGBBAA)
///   * Color(0x1A000000) ⇔ "#0000001A"
///   * Color(0x33585213) ⇔ "#58521333"
/// {@endtemplate}
class ColorConverter implements JsonConverter<Color, String> {
  /// {@macro color_converter}
  const ColorConverter({this.containsHash = true});

  /// Whether [toJson] should include a leading `#` in the output string.
  ///
  /// This does **not** affect parsing: [fromJson] accepts both forms.
  final bool containsHash;

  @override
  Color fromJson(String json) {
    // 1) Normalize and validate the input string to match the “RRGGBBAA” format.
    final rgbaHex = _validateAndNormalize(json); // "RRGGBBAA"
    final rgbaValue = int.parse(rgbaHex, radix: 16);

    // 2) Convert RGBA (RRGGBBAA) to ARGB (AARRGGBB) values.
    final argbValue = _rgbaToArgb(rgbaValue);

    // 3) dart:ui's Color uses AARRGGBB (ARGB).
    return Color(argbValue);
  }

  @override
  String toJson(Color color) {
    return _colorToHex(color);
  }

  /// Normalizes and validates an input hex string.
  ///
  /// - Trims whitespace
  /// - Removes a single leading '#' if present
  /// - Accepts 6-digit "RRGGBB" (assumes alpha = 0xFF)
  /// - Accepts 8-digit "RRGGBBAA"
  ///
  /// Returns the normalized "RRGGBBAA" hex string (no '#').
  String _validateAndNormalize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Hex color string must not be empty');
    }

    // remove optional '#'
    final raw = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (raw.isEmpty) {
      throw ArgumentError('Hex color string must not be empty');
    }

    // Expand shorthand HEX (#RGB, #RGBA)
    String hex;
    switch (raw.length) {
      case 3: // RGB -> RRGGBBFF
        hex = '${raw.split('').map((c) => '$c$c').join()}FF';
      case 4: // RGBA -> RRGGBBAA
        final chars = raw.split('');
        hex = chars.map((c) => '$c$c').join();
      case 6: // RRGGBB -> RRGGBBFF
        hex = '${raw}FF';
      case 8: // RRGGBBAA
        hex = raw;
      default:
        throw FormatException(
          'Hex color must be 3, 4, 6, or 8 characters. Got ${raw.length}',
          input,
        );
    }

    if (int.tryParse(hex, radix: 16) == null) {
      throw FormatException('Invalid hex color string: $input', input);
    }

    return hex.toUpperCase();
  }

  /// Converts a RGBA int (`RRGGBBAA`) into an ARGB int (`AARRGGBB`) used by [Color].
  int _rgbaToArgb(int rgba) {
    final r = (rgba >> 24) & 0xFF;
    final g = (rgba >> 16) & 0xFF;
    final b = (rgba >> 8) & 0xFF;
    final a = rgba & 0xFF;

    // AARRGGBB
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Converts a [Color] to a web/Figma-style `RRGGBBAA` hex string, optionally prefixed with '#'.
  String _colorToHex(Color color) {
    final rgba = _colorToRgbaInt(color);
    final hex = rgba.toRadixString(16).padLeft(8, '0').toUpperCase();
    final prefix = containsHash ? '#' : '';
    return '$prefix$hex';
  }

  /// Converts a [Color] into a RGBA int (`RRGGBBAA`).
  int _colorToRgbaInt(Color color) {
    // The red/green/blue/alpha properties are each integers ranging from 0 to 255.
    return ((color.r * 255).round().clamp(0, 255) << 24) |
        ((color.g * 255).round().clamp(0, 255) << 16) |
        ((color.b * 255).round().clamp(0, 255) << 8) |
        (color.a * 255).round().clamp(0, 255);
  }
}
