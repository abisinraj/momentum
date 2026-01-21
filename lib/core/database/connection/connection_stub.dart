import 'package:drift/drift.dart';

import 'connection.dart' as impl;

/// Open database connection - delegates to platform-specific implementation
QueryExecutor openConnection() {
  return impl.openConnection();
}
