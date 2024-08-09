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
  Database? db;
  double _progress = 0.0;
  bool _isUpdating = false;


  @override
  void initState() {
    super.initState();
    _initializeDatabase().then((_) {
      if (kDebugMode) {
        print('Database initialized in initState');
      }
    });
  }

  Future<void> _initializeDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final dbPath = join(databasePath, 'ghanaian_towns.db');

      db = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
        await db.execute('CREATE TABLE towns (id INTEGER PRIMARY KEY, name TEXT)');
      });

      if (kDebugMode) {
        print('Database Initialized successfully');
      }

      final count = await db!.query('towns').then((value) => value.length);
      if (count == 0) {
        await loadCSVAndInsertIntoDatabase(db!);
        if (kDebugMode) {
          print('Towns loaded from CSV to database successfully');
        }
      }

      // Fetch towns from the database
      await getTownsFromDatabase(db!);
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

      if (kDebugMode) {
        print('Loaded towns: $ghanaianTowns');
        print('Length of ghanaianTowns: ${ghanaianTowns.length}');
      }

      setState(() {}); // Update the state to refresh the UI with the new data
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

  Future<void> resetUI() async {
    setState(() {
      generatedTown = '';
    });
  }

  Future<void> updateDatabase() async {
    try {
      if (db == null) {
        if (kDebugMode) {
          print('Database is not initialized');
        }
        return;
      }

      setState(() {
        _isUpdating = true;
        _progress = 0.0; // Reset progress at the start
      });

      if (kDebugMode) {
        print('Clearing database...');
      }
      await clearDatabase(db!);

      if (kDebugMode) {
        print('Loading towns from CSV...');
      }
      final String csvData = await rootBundle.loadString('assets/ghanaian_towns.csv');
      final List<List<dynamic>> parsedData = const CsvToListConverter().convert(csvData, eol: "\n");

      final totalRows = parsedData.length;
      int insertedRows = 0;

      await db!.transaction((txn) async {
        for (int i = 0; i < totalRows; i++) {
          final row = parsedData[i];
          final townName = row[0] as String;
          if (townName.isNotEmpty) {
            await txn.insert('towns', {'name': townName});
          }
          insertedRows++;

          // Update progress
          setState(() {
            _progress = insertedRows / totalRows;
          });
        }
      });

      setState(() {
        _isUpdating = false;
        resetUI();
        if (kDebugMode) {
          print('Database update complete.');
        }
      });
    } catch (error) {
      setState(() {
        _isUpdating = false;
      });
      if (kDebugMode) {
        print('Error during database update: $error');
      }
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
                const SizedBox(height: 40),
                if (_isUpdating) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Updating Database...'),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: _progress),
                        const SizedBox(height: 8),
                        Text('${(_progress * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: generateRandomTown,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700], // Darker green
                              foregroundColor: Colors.white, // White text color
                            ),
                            child: const Text('Generate Town'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: resetUI,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700], // Darker blue
                              foregroundColor: Colors.white, // White text color
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: updateDatabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700], // Darker red
                              foregroundColor: Colors.white, // White text color
                            ),
                            child: const Text('Update Database'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}
