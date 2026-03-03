/// Información generada automáticamente en cada build.
/// Se inyecta via: --dart-define=BUILD_DATE="dd/mm/yyyy"
library build_info;

const String kBuildDate = String.fromEnvironment(
  'BUILD_DATE',
  defaultValue: '',
);
