import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cats_flutter/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      await db.delete('cats');
    });

    test('Test 1', () async {
      final testCat = Cat(
        imageUrl: 'url',
        name: 'Cat',
        description: 'Description',
        date: DateTime.now(),
      );

      final id = await dbHelper.insertCat(testCat);
      expect(id, greaterThan(0));

      final cats = await dbHelper.getAllCats();
      expect(cats.length, 1);
      expect(cats[0].id, id);
      expect(cats[0].name, 'Cat');
    });

    test('Test 2', () async {
      final testCat = Cat(
        imageUrl: 'url',
        name: 'Cat',
        description: 'Description',
        date: DateTime.now(),
      );

      await dbHelper.insertCat(testCat);
      var cats = await dbHelper.getAllCats();
      await dbHelper.deleteCat(cats[0].id!);

      cats = await dbHelper.getAllCats();
      expect(cats.length, 0);
    });

    test('Test 3', () async {
      final testDate = DateTime(2024, 1, 1);
      final testCat = Cat(
        imageUrl: 'url',
        name: 'Cat',
        description: 'Description',
        date: testDate,
      );

      await dbHelper.insertCat(testCat);
      final cats = await dbHelper.getAllCats();

      expect(cats[0].imageUrl, 'url');
      expect(cats[0].description, 'Description');
      expect(cats[0].date, testDate);
    });
  });
}
