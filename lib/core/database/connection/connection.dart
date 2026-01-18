// Conditional export for database connection
export 'native.dart' if (dart.library.html) 'web.dart';
