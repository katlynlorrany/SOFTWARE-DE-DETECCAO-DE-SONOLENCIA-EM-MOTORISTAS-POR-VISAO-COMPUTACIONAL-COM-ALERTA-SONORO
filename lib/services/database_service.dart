import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('empresa_frotas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrementado para atualizar a estrutura
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE funcionarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cpf TEXT UNIQUE,
            nome TEXT,
            data_nascimento TEXT,
            email TEXT UNIQUE,
            telefone TEXT,
            empresa TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS funcionarios');
          await db.execute('''
            CREATE TABLE funcionarios (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              cpf TEXT UNIQUE,
              nome TEXT,
              data_nascimento TEXT,
              email TEXT UNIQUE,
              telefone TEXT,
              empresa TEXT
            )
          ''');
        }
      },
    );
  }

  Future<int> inserirFuncionario(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('funcionarios', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> fazerLoginPorEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'funcionarios',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }
}