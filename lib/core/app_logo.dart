import 'package:flutter/material.dart';

/// Logo do app, com variante clara/escura conforme o tema.
///
/// O arquivo é escolhido pelo [Brightness] do tema e a resolução pelo
/// `devicePixelRatio` do dispositivo (128, 256 ou 512 px).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  /// Lado do logo em pixels lógicos.
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetPixels = size * dpr;

    final resolution = targetPixels > 384
        ? '512'
        : targetPixels > 192
            ? '256'
            : '128';
    final variant = isDark ? 'dark' : 'light';
    final asset = 'assets/logo/logo_${variant}_$resolution.png';

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
