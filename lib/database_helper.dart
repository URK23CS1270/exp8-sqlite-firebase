import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    databaseFactory = databaseFactoryFfiWeb;

    return await openDatabase(
      'students.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            course TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // CREATE
  Future<int> insertStudent(
      String name, String course) async {
    final db = await database;

    return await db.insert(
      'students',
      {
        'name': name,
        'course': course,
      },
    );
  }

  // READ
  Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await database;

    return await db.query(
      'students',
      orderBy: 'id DESC',
    );
  }

  // UPDATE
  Future<int> updateStudent(
      int id,
      String name,
      String course) async {
    final db = await database;

    return await db.update(
      'students',
      {
        'name': name,
        'course': course,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<int> deleteStudent(int id) async {
    final db = await database;

    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}