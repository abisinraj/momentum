import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web database connection using sql.js (IndexedDB persistence)
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'momentum_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    
    if (result.missingFeatures.isNotEmpty) {
      print('Missing web features: ${result.missingFeatures}');
    }
    
    return result.resolvedExecutor;
  });
}
