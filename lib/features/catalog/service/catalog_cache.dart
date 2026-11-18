import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:assessment_project_fb_international_frontend/core/config/api_config.dart';
import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/config/mobile_platform.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/catalog_state.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';

final catalogCacheProvider = Provider<CatalogCache?>((ref) {
  if (!isNativeMobile || ref.watch(demoModeProvider)) return null;
  return CatalogCache(ref.watch(apiBaseUrlProvider));
});

/// One ordered, validated public catalog per API base URL. The separate
/// timestamp row also represents a successful response containing zero items.
class CatalogCache {
  CatalogCache(this.source);
  final String source;
  static const _path = 'explore_catalog.db';

  // sqflite shares the connection by path and retries a failed open on next use.
  Future<T?> _use<T>(Future<T> Function(Database db) operation) async {
    try {
      final db = await openDatabase(
        _path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
          CREATE TABLE catalog_snapshot (
            source TEXT PRIMARY KEY, updated_at INTEGER NOT NULL
          )
        ''');
          await db.execute('''
          CREATE TABLE catalog_service (
            source TEXT NOT NULL, position INTEGER NOT NULL, payload TEXT NOT NULL,
            PRIMARY KEY (source, position)
          )
        ''');
        },
      );
      return await operation(db);
    } catch (error) {
      developer.log(
        'Catalog cache unavailable (${error.runtimeType})',
        name: 'autocare.cache',
      );
      return null;
    }
  }

  Future<CatalogState?> read() => _use<CatalogState?>(
    (db) => db.transaction((txn) async {
      final snapshot = await txn.query(
        'catalog_snapshot',
        where: 'source = ?',
        whereArgs: [source],
      );
      if (snapshot.isEmpty) return null;
      final rows = await txn.query(
        'catalog_service',
        columns: ['payload'],
        where: 'source = ?',
        whereArgs: [source],
        orderBy: 'position',
      );
      return CatalogState(
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          snapshot.single['updated_at'] as int,
          isUtc: true,
        ),
        services: List.unmodifiable(
          rows.map(
            (row) => decodeJson(
              jsonDecode(row['payload'] as String),
              ServiceModel.fromJson,
            ),
          ),
        ),
      );
    }),
  );

  Future<void> write(List<ServiceModel> services, DateTime updatedAt) =>
      _use<void>((db) async {
        final batch = db.batch();
        batch.insert('catalog_snapshot', {
          'source': source,
          'updated_at': updatedAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        batch.delete(
          'catalog_service',
          where: 'source = ?',
          whereArgs: [source],
        );
        for (var i = 0; i < services.length; i++) {
          batch.insert('catalog_service', {
            'source': source,
            'position': i,
            'payload': jsonEncode(services[i].toJson()),
          });
        }
        // Batch.commit wraps the replacement in a single SQLite transaction.
        await batch.commit(noResult: true);
      });

  Future<void> expire() => _use<void>((db) async {
    await db.update(
      'catalog_snapshot',
      {'updated_at': 0},
      where: 'source = ?',
      whereArgs: [source],
    );
  });
}
