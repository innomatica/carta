import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/cartabook.dart';
import '../model/cartaserver.dart';
import '../shared/helpers.dart';

const databaseName = 'carta_database.db';
const databaseVersion = 3;
const tableAudioBooks = 'audiobooks';
const tableBookServers = 'bookservers';
const sqlCreateAudioBooks = 'CREATE TABLE $tableAudioBooks ('
    'bookId TEXT UNIQUE,'
    'title TEXT NOT NULL,'
    'authors TEXT NOT NULL,'
    'description TEXT,'
    'language TEXT,'
    'imageUri TEXT,'
    'duration TEXT,'
    'lastSection INTEGER,'
    'lastPosition TEXT,'
    'source INTEGER NOT NULL,'
    'info TEXT NOT NULL,'
    'sections TEXT)';
const sqlCreateBookServers = 'CREATE TABLE $tableBookServers ('
    'serverId TEXT UNIQUE,'
    'title TEXT NOT NULL,'
    'type INTEGER,'
    'url TEXT,'
    'settings TEXT)';
const sqlCreateTables = <String>[sqlCreateAudioBooks, sqlCreateBookServers];

const sqlDropAudioBooks = 'DROP TABLE $tableAudioBooks';
const sqlDropBookServers = 'DROP TABLE $tableBookServers';
const sqlDropTables = <String>[sqlDropAudioBooks, sqlDropBookServers];

class SqliteRepo {
  // make this class singleton
  SqliteRepo._internal();
  static final SqliteRepo _instance = SqliteRepo._internal();
  factory SqliteRepo() {
    return _instance;
  }

  Database? _db;

  Future open() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, databaseName);
    logDebug('database: $path');

    _db = await openDatabase(
      databaseName,
      version: databaseVersion,
      onCreate: (db, version) async {
        for (final sql in sqlCreateTables) {
          await db.execute(sql);
        }
        // populate sample data here
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        logDebug('version upgrade from $oldVersion to $newVersion');
        if (oldVersion < 3) {
          for (final sql in sqlDropTables) {
            await db.execute(sql);
          }
          for (final sql in sqlCreateTables) {
            await db.execute(sql);
          }
        }
      },
    );
  }

  void close() async {
    await _db?.close();
  }

  Future<Database> getDatabase() async {
    if (_db == null) {
      await open();
    }
    return _db!;
  }

  //
  // CartaBook
  //
  // Create
  Future<int> addAudioBook(CartaBook book) async {
    // logDebug('addAudioBook: ${book.toString()}');
    final db = await getDatabase();
    return db.insert(
      tableAudioBooks,
      book.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read
  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    final db = await getDatabase();
    final records =
        await db.query(tableAudioBooks, where: 'bookId=?', whereArgs: [bookId]);
    if (records.isNotEmpty) {
      return CartaBook.fromSqlite(records.first);
    }
    return null;
  }

  // Read Collection
  Future<List<CartaBook>> getAudioBooks({Map<String, dynamic>? query}) async {
    final db = await getDatabase();
    final records = await db.query(
      tableAudioBooks,
      distinct: query?['distinct'],
      columns: query?['columns'],
      where: query?['where'],
      whereArgs: query?['whereArgs'],
      groupBy: query?['groupBy'],
      having: query?['having'],
      orderBy: query?['orderBy'],
      limit: query?['limit'],
      offset: query?['offset'],
    );
    // logDebug('sqlite.getAudioBooks:$records');
    return records.map<CartaBook>((e) => CartaBook.fromSqlite(e)).toList();
  }

  // Update
  Future<int> updateAudioBook(CartaBook book) async {
    // logDebug('updateAudioBook: ${book.toString()}');
    // if (book.id == null) {
    //   return 0;
    // }
    final db = await getDatabase();
    return db.update(
      tableAudioBooks,
      book.toSqlite(),
      where: 'bookId=?',
      whereArgs: [book.bookId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update Data
  // Warning: data conversion has to be done by the caller
  Future<int> updateAudioBooks(
      {required Map<String, Object?> values,
      Map<String, dynamic>? params}) async {
    final db = await getDatabase();
    return db.update(
      tableAudioBooks,
      values,
      where: params?['where'],
      whereArgs: params?['whereArgs'],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete
  Future<int> deleteAudioBook(CartaBook book) async {
    final db = await getDatabase();
    return db.delete(
      tableAudioBooks,
      where: 'bookId = ?',
      whereArgs: [book.bookId],
    );
  }

  // Delete by Id
  Future<int> deleteAudioBookByBookId(String bookId) async {
    final db = await getDatabase();
    return db.delete(
      tableAudioBooks,
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
  }

  //
  // CartaServer
  //
  // Create
  Future<int> addBookServer(CartaServer server) async {
    final db = await getDatabase();
    return db.insert(
      tableBookServers,
      server.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read
  Future<CartaServer?> getBookServerById(String serverId) async {
    final db = await getDatabase();
    final res = await db.query(
      tableBookServers,
      where: 'where',
      whereArgs: [serverId],
    );
    if (res.isNotEmpty) {
      return CartaServer.fromSqlite(res[0]);
    }
    return null;
  }

  // Read Collection
  Future<List<CartaServer>> getBookServers(
      {Map<String, dynamic>? query}) async {
    final db = await getDatabase();
    final settings = await db.query(
      tableBookServers,
      distinct: query?['distinct'],
      columns: query?['columns'],
      where: query?['where'],
      whereArgs: query?['whereArgs'],
      groupBy: query?['groupBy'],
      having: query?['having'],
      orderBy: query?['orderBy'],
      limit: query?['limit'],
      offset: query?['offset'],
    );
    return settings.map<CartaServer>((e) => CartaServer.fromSqlite(e)).toList();
  }

  // Update
  Future<int> updateBookServer(CartaServer server) async {
    final db = await getDatabase();
    return db.update(
      tableBookServers,
      server.toSqlite(),
      where: 'serverId=?',
      whereArgs: [server.serverId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete
  Future<int> deleteBookServer(CartaServer server) async {
    final db = await getDatabase();
    return db.delete(
      tableBookServers,
      where: 'serverId=?',
      whereArgs: [server.serverId],
    );
  }
}
