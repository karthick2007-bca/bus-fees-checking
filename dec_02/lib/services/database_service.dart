import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'bus_fees.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students(
            id TEXT PRIMARY KEY,
            name TEXT,
            phone TEXT,
            email TEXT,
            location TEXT,
            amount REAL,
            status TEXT,
            lastPayment TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE locations(
            id TEXT PRIMARY KEY,
            name TEXT,
            amount REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            studentPhone TEXT,
            amount REAL,
            paymentId TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertStudent(Map<String, dynamic> student) async {
    final db = await database;
    await db.insert('students', student, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await database;
    return await db.query('students');
  }

  static Future<void> updateStudent(String phone, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('students', data, where: 'phone = ?', whereArgs: [phone]);
  }

  static Future<void> deleteStudent(String id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    await db.insert('locations', location, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query('locations');
  }

  static Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert('transactions', transaction);
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'timestamp DESC');
  }
}
