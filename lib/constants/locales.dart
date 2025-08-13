import 'dart:ui';

// Check immich mobile/lib/constants/locales.dart for the original file content
const Map<String, Locale> locales = {
  // Default locale
  'English (en)': Locale('en'),
};

const String translationsPath = 'assets/i18n';

const List<Locale> localesNotSupportedByOverpass = [
  Locale('el', 'GR'),
  Locale('sr', 'Cyrl'),
];
