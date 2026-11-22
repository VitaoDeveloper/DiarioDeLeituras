import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logo.dart';

/// Estado da surpresa: false até alguém descobrir o gesto escondido.
///
/// Não existe nenhum botão, texto ou dica na interface apontando para aqui.
class SurpresaController extends Notifier<bool> {
  @override
  bool build() => false;

  void reveal() => state = true;

  void hide() => state = false;
}

final surpresaProvider =
    NotifierProvider<SurpresaController, bool>(SurpresaController.new);

/// O logo do menu lateral continua com a mesma aparência de sempre, mas
/// esconde o gatilho: [tapsRequired] toques rápidos revelam a surpresa.
class LogoComSurpresa extends ConsumerStatefulWidget {
  const LogoComSurpresa({super.key, this.size = 40});

  /// Quantidade de toques rápidos necessários para abrir o segredo.
  static const tapsRequired = 7;

  /// Lado do logo em pixels lógicos (mesmo contrato de [AppLogo]).
  final double size;

  @override
  ConsumerState<LogoComSurpresa> createState() => _LogoComSurpresaState();
}

class _LogoComSurpresaState extends ConsumerState<LogoComSurpresa> {
  static const gestureWindow = Duration(seconds: 3);

  int _taps = 0;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > gestureWindow) {
      _taps = 0;
    }
    _lastTap = now;
    _taps += 1;

    if (_taps >= LogoComSurpresa.tapsRequired) {
      _taps = 0;
      _lastTap = null;
      ref.read(surpresaProvider.notifier).reveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      // Sem tooltip, sem semantics e sem mudança visual: ninguém percebe
      // que o logo é interativo até acertar a sequência.
      child: AppLogo(size: widget.size),
    );
  }
}

/// Tela cheia que aparece somente depois do gesto secreto.
///
/// Deve ser usada dentro do [Stack] do [MaterialApp.builder].
class SurpresaOverlay extends ConsumerWidget {
  const SurpresaOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(surpresaProvider.notifier).hide(),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return Container(
              color: Color.lerp(
                Colors.transparent,
                const Color(0xF5080A0D),
                progress,
              ),
              child: Center(
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * progress,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/surpresa/marca.png',
                width: 224,
                height: 224,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.shield_outlined,
                  size: 180,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Vai Corinthians!',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Toque em qualquer lugar para voltar',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
