import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale;

  LocaleProvider(Locale initialLocale) : _locale = initialLocale;

  Locale get locale => _locale;
  bool get isSpanish => _locale.languageCode == 'es';
  AppStrings get strings => isSpanish ? AppStrings.es : AppStrings.en;

  /// Carga el idioma guardado por el usuario; si no existe, usa el idioma del
  /// sistema (español si es 'es', inglés en cualquier otro caso).
  static Future<Locale> loadSavedLocale(Locale systemLocale) async {
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/.fdpa_locale');
        if (await file.exists()) {
          final code = (await file.readAsString()).trim();
          if (code == 'es' || code == 'en') return Locale(code);
        }
      } catch (_) {}
    }
    // Predeterminado: español si el sistema es español, inglés en otro caso
    return systemLocale.languageCode == 'es'
        ? const Locale('es')
        : const Locale('en');
  }

  /// Cambia el idioma y lo persiste para la próxima sesión.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/.fdpa_locale');
        await file.writeAsString(locale.languageCode);
      } catch (_) {}
    }
  }
}
