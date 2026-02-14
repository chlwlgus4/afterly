import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/shooting_session.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'afterly.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            lastShootingAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE shooting_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerId INTEGER NOT NULL,
            beforeImagePath TEXT,
            afterImagePath TEXT,
            alignedBeforePath TEXT,
            alignedAfterPath TEXT,
            jawlineScore REAL,
            symmetryScore REAL,
            skinToneScore REAL,
            summary TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (customerId) REFERENCES customers (id)
          )
        ''');
      },
    );
  }

  // --- Customer CRUD ---

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query(
      'customers',
      orderBy: 'lastShootingAt DESC, createdAt DESC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('shooting_sessions', where: 'customerId = ?', whereArgs: [id]);
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- ShootingSession CRUD ---

  Future<int> insertSession(ShootingSession session) async {
    final db = await database;
    return db.insert('shooting_sessions', session.toMap());
  }

  Future<List<ShootingSession>> getSessionsForCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'shooting_sessions',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => ShootingSession.fromMap(m)).toList();
  }

  Future<ShootingSession?> getSession(int id) async {
    final db = await database;
    final maps = await db.query('shooting_sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ShootingSession.fromMap(maps.first);
  }

  Future<void> updateSession(ShootingSession session) async {
    final db = await database;
    await db.update(
      'shooting_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete('shooting_sessions', where: 'id = ?', whereArgs: [id]);
  }
}
