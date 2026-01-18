import 'package:drift/drift.dart';

import 'app_database.dart';
import 'connection/connection.dart' as impl;

/// Open database connection - delegates to platform-specific implementation
QueryExecutor openConnection() {
  return impl.openConnection();
}
