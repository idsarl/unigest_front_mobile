import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'unigest.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE seances (
        id INTEGER PRIMARY KEY, affectation_id INTEGER, matiere TEXT,
        professeur TEXT, classe TEXT, classe_id INTEGER, filiere TEXT,
        heure_debut TEXT, heure_fin TEXT, statut TEXT, cached_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE etudiants (
        id INTEGER PRIMARY KEY, nom TEXT, prenom TEXT, matricule TEXT,
        classe_id INTEGER, email TEXT, telephone TEXT, cached_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE appels_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seance_id INTEGER, etudiant_id INTEGER, statut TEXT,
        minutes_retard INTEGER DEFAULT 0, motif TEXT,
        synced INTEGER DEFAULT 0, created_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE offline_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        method TEXT, endpoint TEXT, payload TEXT,
        synced INTEGER DEFAULT 0, created_at INTEGER
      )
    ''');
  }

  // ── Seances ──────────────────────────────────────────────────────────────

  static Future<void> cacheSeances(List<Map<String, dynamic>> rows) async {
    final d = await db;
    final batch = d.batch();
    for (final row in rows) {
      batch.insert('seances', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getSeancesOffline() async {
    final d = await db;
    return d.query('seances', orderBy: 'heure_debut ASC');
  }

  static Future<void> updateSeanceStatut(int seanceId, String statut) async {
    final d = await db;
    await d.update(
      'seances',
      {'statut': statut},
      where: 'id = ?',
      whereArgs: [seanceId],
    );
  }

  // ── Etudiants ─────────────────────────────────────────────────────────────

  static Future<void> cacheEtudiants(
      int classeId, List<Map<String, dynamic>> rows) async {
    final d = await db;
    await d.delete('etudiants', where: 'classe_id = ?', whereArgs: [classeId]);
    final batch = d.batch();
    for (final row in rows) {
      batch.insert('etudiants', {...row, 'classe_id': classeId},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getEtudiantsOffline(
      int classeId) async {
    final d = await db;
    return d.query('etudiants',
        where: 'classe_id = ?', whereArgs: [classeId], orderBy: 'nom ASC');
  }

  // ── Actions hors-ligne ────────────────────────────────────────────────────

  static Future<void> queueAction(
      String method, String endpoint, String payload) async {
    final d = await db;
    await d.insert('offline_actions', {
      'method': method,
      'endpoint': endpoint,
      'payload': payload,
      'synced': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final d = await db;
    return d.query('offline_actions',
        where: 'synced = 0', orderBy: 'created_at ASC');
  }

  static Future<void> markActionSynced(int id) async {
    final d = await db;
    await d.update('offline_actions', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}
