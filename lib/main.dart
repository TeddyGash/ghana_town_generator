import 'dart:convert';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const GhanaTownGenerator());
}

class GhanaTownGenerator extends StatefulWidget {
  const GhanaTownGenerator({super.key});

  @override
  _GhanaTownGeneratorState createState() => _GhanaTownGeneratorState();
}

class _GhanaTownGeneratorState extends State<GhanaTownGenerator> {
  String generatedTown = '';
  List<String> ghanaianTowns = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }


  Future<void> _initializeDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final dbPath = join(databasePath, 'ghanaian_towns.db');

      final db = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
        await db.execute('CREATE TABLE towns (id INTEGER PRIMARY KEY, name TEXT)');
      });

      if (kDebugMode) {
        print('Database Initialised successfully');
      }

      await clearDatabase(db);
      if (kDebugMode) {
        print('Database cleared successfully');
      }

      final count = await db.query('towns').then((value) => value.length);
      if (count == 0) {
        await loadCSVAndInsertIntoDatabase(db);
        if (kDebugMode) {
          print('Towns loaded from csv to database successfully');
        }

      }

      // Fetch towns from the database
      await getTownsFromDatabase(db);
    } catch (error) {
      if (kDebugMode) {
        print('Error initializing database: $error');
      }
    }
  }

  Future<void> getTownsFromDatabase(Database db) async {
    try {
      final maps = await db.query('towns');
      ghanaianTowns = List.generate(maps.length, (i) {
        return maps[i]['name'] as String;
      });
      // Debugging: Print the list contents and length
      if (kDebugMode) {
        print('Loaded towns: $ghanaianTowns');
      }
      if (kDebugMode) {
        print('Length of ghanaianTowns: ${ghanaianTowns.length}');
      }
      setState(() {}); // Update the state to refresh the UI with the new data

      // Debugging: Print the list contents and length
      if (kDebugMode) {
        print('Loaded towns: $ghanaianTowns');
      }
      if (kDebugMode) {
        print('Length of ghanaianTowns: ${ghanaianTowns.length}');
      }

    } catch (error) {
      if (kDebugMode) {
        print('Error fetching towns from database: $error');
      }
    }
  }

  Future<void> clearDatabase(Database db) async {
    try {
      // Clear existing data from the 'towns' table
      await db.delete('towns');


    } catch (error) {
      if (kDebugMode) {
        print('Error clearing database: $error');
      }
    }
  }

  Future<void> loadCSVAndInsertIntoDatabase(Database db) async {
    // Load CSV data
    final String csvData = await rootBundle.loadString('assets/ghanaian_towns.csv');

    // Parse CSV data
    final List<List<dynamic>> parsedData = const CsvToListConverter().convert(csvData, eol: "\n");

    // Debugging: Print parsed CSV data
    if (kDebugMode) {
      print('Parsed CSV Data: $parsedData');
      print('Length of Parsed CSV Data: ${parsedData.length}');
    }


    // Initialize your database and perform insertions
    // Note: Ensure your database initialization and transactions are correct

    // final Database db = await initializeDatabase(); // Replace with your actual database initialization method

    await db.transaction((txn) async {
      // Skip the header row if it exists
      for (int i = 0; i < parsedData.length; i++) {
        final row = parsedData[i];
        final townName = row[0] as String;
        if (townName.isNotEmpty) {
          await txn.insert('towns', {'name': townName});
        }
      }
    });

    if (kDebugMode) {
      print('Towns loaded from CSV to database successfully');
    }
  }


  /*Future<void> loadTownNamesFromCSV(Database db) async {
    try {
      // Clear existing data from the 'towns' table
      //await db.delete('towns');

      // Load CSV file
      final bytes = await rootBundle.load('assets/ghanaian_towns.csv');
      final string = utf8.decode(bytes.buffer.asUint8List());
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(string);

      // Debugging: Print the CSV data
      if (kDebugMode) {
        print('CSV Data: $csvData');
        print('Length of CSV Data: ${csvData.length}');
      }

      // Insert new data into the 'towns' table
      await db.transaction((txn) async {
        for (int i = 1; i < csvData.length; i++) { // Start from 1 to skip header
          final column = csvData[i];
          final townName = column[0] as String;
          if (townName.isNotEmpty) {
            await txn.insert('towns', {'name': townName});
          }
        }
      });

      // Optionally verify the number of rows inserted
      final count = await db.query('towns').then((value) => value.length);
      if (kDebugMode) {
        print('Number of towns inserted: $count');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error loading towns from CSV: $error');
      }
    }
  }*/


  void generateRandomTown() {
    if (ghanaianTowns.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(ghanaianTowns.length);
      if (kDebugMode) {
        print('Random index generated: $randomIndex');
      }
      final selectedTown = ghanaianTowns[randomIndex];
      setState(() {
        generatedTown = selectedTown;
        if (kDebugMode) {
          print('Generated Town: $generatedTown');
        }
      });
    } else {
      setState(() {
        generatedTown = 'No towns available';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghana Town Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ghana Town Generator'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    generatedTown.isEmpty
                        ? 'Press the button to generate a town'
                        : generatedTown,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: generateRandomTown,
                  child: const Text('Generate Town'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
