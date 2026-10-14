import 'package:flutter/material.dart';

/// Espaçamentos no grid de 4dp. Use sempre estas constantes
/// em vez de números soltos no código (ex: 16, 12, 8).
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;

  // Atalhos prontos para espaço vertical e horizontal
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vBase = SizedBox(height: base);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
}

/// Raios de borda padronizados
abstract class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

/// Tema único do app (Material 3), claro e escuro.
/// Todas as telas pegam cores e textos daqui, então mudar a marca
/// exige alterar só a cor semente abaixo.
class AppTheme {
  /// Cor de marca: azul técnico, transmite confiança para quem deixa o aparelho
  static const _corMarca = Color(0xFF1E4D8C);

  static ThemeData light() => _montar(Brightness.light);
  static ThemeData dark() => _montar(Brightness.dark);

  static ThemeData _montar(Brightness brilho) {
    // A partir de uma cor só, o Material 3 gera a paleta inteira
    final esquema = ColorScheme.fromSeed(seedColor: _corMarca, brightness: brilho);
    final base = ThemeData(useMaterial3: true, colorScheme: esquema);

    return base.copyWith(
      scaffoldBackgroundColor: esquema.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        surfaceTintColor: Colors.transparent, // evita a cor "lavada" ao rolar
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: esquema.onSurface,
        ),
      ),

      // Títulos um pouco mais fortes para criar hierarquia visual
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),

      // Campos de formulário preenchidos (sem contorno pesado)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: esquema.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
      ),

      // Botões com área de toque confortável (mínimo recomendado: 48dp)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),

      dividerTheme: DividerThemeData(color: esquema.outlineVariant, space: 32),
    );
  }
}

/// Atalhos para escrever menos: context.colors e context.textTheme
extension ContextoTema on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}