// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'credit_card.dart';
import 'search_history.dart';
import 'user.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDatabase();
    return _db!;
  }

  /// Initializes the database.
  ///
  /// This method creates a new database at the specified path and sets up the initial table structure.
  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'database.db');
    // Make a GET request
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON;');

        // Users table
        await db.execute(
          "CREATE TABLE users (userID INTEGER PRIMARY KEY, userEmail TEXT, hashedPassword TEXT, salt TEXT, userPreferences TEXT, createdAt TIMESTAMP, updatedAt TIMESTAMP, deletedAt TIMESTAMP, isThirdParty INTEGER DEFAULT 0)",
        );

        // SearchHistory table
        await db.execute(
          "CREATE TABLE searchHistory (id INTEGER PRIMARY KEY AUTOINCREMENT, userID INT, SearchTerm VARCHAR(255), SearchTime TIMESTAMP, deletedAt TIMESTAMP, FOREIGN KEY(userID) REFERENCES users(userID))",
        );
        // CreditCard table will be only for storing last 4 digets and expiry date
        await db.execute(
          "CREATE TABLE creditCard (subscriptionId TEXT PRIMARY KEY, userID INT, lastDigits TEXT, expiryDate TEXT, createdAt TIMESTAMP, updatedAt TIMESTAMP, deletedAt TIMESTAMP, FOREIGN KEY(userID) REFERENCES users(userID))",
        );

        await db.execute('''
          CREATE TABLE Locations (
            LocationID INTEGER PRIMARY KEY,
            LocationName TEXT,
            Coordinates TEXT,
            CreatedAt TEXT,
            DeletedAt TEXT
          )
          ''');
      },
    );
  }

  /// --------------------------
  /// ------- INSERT ----------
  /// --------------------------

  /// Inserts a new user into the database.
  ///
  /// If a user with the same ID already exists, tsting user is replaced.
  Future<void> insertUser(User user) async {
    final Database db = await this.db;
    String path = await getDatabasesPath();
    print('Database Path: $path');
    // Check if the email already exists
    final List<Map<String, dynamic>> existingUsers = await db.query(
      'users',
      where: "userEmail = ?",
      whereArgs: [user.userEmail],
    );
    if (existingUsers.isNotEmpty) {
      throw Exception('A user with this email already exists.');
    }

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a new search history into the database.
  ///
  /// If a search history with the same userID and searchTime already exists,
  /// the existing search history is replaced.
  Future<void> insertSearchHistory(SearchHistory searchHistory) async {
     String path = await getDatabasesPath();
    print('Database Path: $path');
    final Database db = await this.db;

    await db.insert(
      'searchHistory',
      searchHistory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a list of locations into the local SQLite database.
  ///
  /// This function fetches location data from the server if the 'Locations' table is empty,
  /// and inserts each location into the local SQLite database.
  ///
  /// @param locations The list of locations to insert. Each location should be a Map<String, dynamic>
  /// where the keys are column names and the values are the corresponding values in the row.
  Future<void> insertLocations() async {
    try {
      final Database db = await this.db;

      // Check if the 'Locations' table is empty
      List<Map> result = await db.rawQuery('SELECT * FROM Locations');
      if (result.isEmpty) {
        print('Inserting locations into the database');

        // Fetch data from the server
        var response = await http.get(Uri.parse('http://wavefinderapp.fun/getLocations.php'));

        if (response.statusCode == 200) {
          List<dynamic> locationsJson = jsonDecode(response.body);
          List<Map<String, dynamic>> locations = locationsJson.map((location) => {
            'LocationID': location['locationid'],
            'LocationName': location['locationname'],
            'Coordinates': jsonEncode(location['coordinates']),
            'CreatedAt': location['createdat'],
            'DeletedAt': location['deletedat']
          }).toList();

          // Insert all the locations
          for (var location in locations) {
            await db.insert('Locations', location);
          }
          print('Locations inserted successfully');
        } else {
          // If the server returns an unsuccessful response code, throw an exception.
          throw Exception('Failed to load locations with status code: ${response.statusCode}');
        }
      } else {
        print('Locations table is not empty. No data inserted.');
      }
    } on SocketException catch (e) {
      print('No Internet connection 😑: $e');
    } on HttpException catch (e) {
      print('Couldn\'t find the server 😱: $e');
    } on FormatException catch (e) {
      print('Bad response format 👎: $e');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  /// --------------------------
  /// ------- Update ----------
  /// --------------------------

  /// Updates the password of an existing user in the database.
  ///
  /// The user is identified by their email. Each time this method is
  /// called, the `updatedAt` field is set to the current date and time.
  Future<void> updateUserPassword(String userEmail, String newPassword) async {
    final db = await this.db;

    // Hash the new password
    String newSalt = User.generateSalt();
    String newHashedPassword = User.hashPassword(newPassword, newSalt);

    // Update the password and salt in the database
    await db.update(
      'users',
      {
        'hashedPassword': newHashedPassword,
        'salt': newSalt,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: "userEmail = ?",
      whereArgs: [userEmail],
    );
  }

  /// Updates an existing credit card in the database.
  /// User can have only one card stored in the database
  ///
  /// The credit card is identified by its ID. Each time this method is called,
  /// the `updatedAt` field is set to the current date and time.
  Future<void> replaceCreditCard(String email, CreditCard newCard) async {
    final Database db = await this.db;
    final path = await getDatabasesPath();
    print('Database Path: $path');
    print('CardUpdate');
    // Query the User table to get the userId for the given email
    List<Map<String, dynamic>> userMaps = await db.query(
      'users',
      where: "userEmail = ?",
      whereArgs: [email],
    );

    if (userMaps.isNotEmpty) {
      int userId = userMaps[0]['userID'];

      // Find the existing card for the user
      List<Map<String, dynamic>> cardMaps = await db.query(
        'creditCard',
        where: "userId = ?",
        whereArgs: [userId],
      );

      if (cardMaps.isNotEmpty) {
        await db.update(
          'creditCard',
          {
          'createdAt': cardMaps[0]['createdAt'],
          'updatedAt': DateTime.now().toString(),
          'deletedAt': null,
          ...newCard.toMap(userId),
          },
          where: "userId = ?",
          whereArgs: [userId],
        );
      } else {
        // If no card exists for the user, insert the new card
        await db.insert(
          'creditCard',
          {
            'createdAt': DateTime.now().toString(),
            'updatedAt': DateTime.now().toString(),
            ...newCard.toMap(userId),
          }
        );
      }
    } else {
      print('No user found with this email');
    }
  }

  /// --------------------------
  /// ------- Soft Delete -----
  /// --------------------------

  /// Soft deletes a user from the database.
  ///
  /// The user is identified by their email. Instead of removing the user record,
  /// this method sets the `deletedAt` field to the current date and time.
  /// All related items to the user should also update their `deletedAt` field.
  Future<void> deleteUser(String email) async {
    final db = await this.db;
    final userId = await getUserIDByEmail(email);

    // Soft delete the user
    await db.update(
      'users',
      {
        'deletedAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString()
      },
      where: "userEmail = ?",
      whereArgs: [email],
    );

    // Soft delete related SearchHistory records
    await db.update(
      'searchHistory',
      {
        'deletedAt': DateTime.now().toString(),
      },
      where: "userID = ?",
      whereArgs: [userId],
    );

    // Soft delete related CreditCard records
    await db.update(
      'creditCard',
      {
        'deletedAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString()
      },
      where: "userID = ?",
      whereArgs: [userId],
    );
  }

  /// --------------------------
  /// ------- Auto Destroy -----
  /// --------------------------

  /// Automatically destroys users who have been soft-deleted for more than 7 days.
  ///
  /// This method first calculates the date 7 days prior to the current date.
  /// It then queries the database for users who were soft-deleted on or before that date.
  /// Each user found is then permanently deleted from the database.
  Future<void> autoDestroyUsers() async {
    final db = await this.db;
    print('Destroying users');
    // Get the date 7 days ago
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Find users where deletedAt is more than 7 days ago
    List<Map<String, dynamic>> usersToDelete = await db.query(
      'users',
      where: "deletedAt <= ? AND deletedAt IS NOT NULL",
      whereArgs: [sevenDaysAgo.toIso8601String()],
    );

    // Delete each user found and their related records
    for (var user in usersToDelete) {
      int userId = user['userID'];

      // Delete related SearchHistory records
      await db.delete(
        'SearchHistory',
        where: "userID = ?",
        whereArgs: [userId],
      );

      // Delete related CreditCard records
      await db.delete(
        'CreditCard',
        where: "userID = ?",
        whereArgs: [userId],
      );

      // Delete the user
      await db.delete(
        'users',
        where: "userID = ?",
        whereArgs: [userId],
      );
    }
  }

  /// --------------------------
  /// ------- GETTERS ----------
  /// --------------------------

  /// Fetches a user's ID based on their email.
  ///
  /// This method queries the database for a user with the given email and returns their ID.
  /// If no user is found with the given email, this method throws an Exception.
  /// @return [Integer] userID
  Future<int> getUserIDByEmail(String email) async {
    final db = await this.db;

    // Query the database for a user with the given email
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: "userEmail = ? AND deletedAt IS NULL",
      whereArgs: [email],
    );

    // If no user is found, throw an exception
    if (maps.isEmpty) {
      throw Exception('No user found with this email');
    }

    // Return the user's ID
    return maps[0]['userID'];
  }

  /// Authenticates a user with the provided email and password.
  ///
  /// Returns true if authentication is successful, false otherwise.
  Future<bool> validateUserCredentials(String email, String password) async {
    final Database db = await this.db;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: "userEmail = ?",
      whereArgs: [email],
    );

    if (users.isEmpty) {
      return false; // User with this email does not exist
    }

    final user = users.first;

    return User.verifyPassword(password.trim(), user['hashedPassword'], user['salt']);
  }

  /// CHeck if user exist in my database
  ///
  /// @return [Boolean]
  Future<bool> userExists(String email) async {
    final Database db = await this.db;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: "userEmail = ?",
      whereArgs: [email],
    );

    return (users.isNotEmpty);
  }

  /// Fetches a user based on their email.
  ///
  /// @return [User]
  Future<User?> getUser(String email) async {
    final Database db = await this.db;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: "userEmail = ?",
      whereArgs: [email],
    );

    if (users.isNotEmpty) {
      // Convert the Map to a User object and return it
      return User.fromMap(users.first);
    }

    // If the user doesn't exist, return null
    return null;
  }

  /// Fetches a user based on their email. valid user which is not
  /// soft deleted.
  ///
  /// @return [User]
   Future<User?> getValidUser(String email) async {
    final User? user = await getUser(email);

    if (user != null && user.deletedAt == null) {
      return user;
    }

    return null;
  }

  /// Recover users account
  Future<void> recoverUser(String email) async {
    final Database db = await this.db;
    await db.update(
      'users',
      {'deletedAt': null},
      where: "userEmail = ?",
      whereArgs: [email],
    );
  }

  /// Fetches a CreditCard based on users email.
  ///
  /// @return [CreditCard]
  Future<CreditCard?> getUserCard(String email) async {
    try {
      final Database db = await this.db;
      int userId = await getUserIDByEmail(email);

      // Find the existing card for the user
      List<Map<String, dynamic>> cardMaps = await db.query(
        'CreditCard',
        where: "userId = ? AND deletedAt IS NULL",
        whereArgs: [userId],
      );

      if (cardMaps.isNotEmpty) {
        return CreditCard.fromMap(cardMaps.first);
      } else {
        return null; // No card found for the user
      }
    } catch (e) {
      // Handle any potential errors, such as database errors or exceptions
      print('Error fetching user card: $e');
      return null; // Return null to indicate failure
    }
  }

  /// Delete soft a CreditCard based on users email.
  Future<void> deleteUserCard(String email) async {
    final Database db = await this.db;
    int userId = await getUserIDByEmail(email);

    await db.update(
      'creditCard',
      {
      'deletedAt': DateTime.now().toString(),
      },
      where: "userID = ?",
      whereArgs: [userId],
    );
  }

  /// Checks if the user has a subscription based on whether they have a valid credit card.
  ///
  /// @return true if the user has a subscription, false otherwise.
  Future<bool> hasSubscription(String email) async {
    try {
      final CreditCard? userCard = await getUserCard(email);
      return userCard != null;
    } catch (e) {
      // Handle any potential errors
      print('Error checking subscription status: $e');
      return false;
    }
  }

  /// Fetches all location names from the 'Locations' table in the database.
  ///
  /// Returns a list of maps where each map represents a row in the 'Locations' table.
  /// Each map contains a single key-value pair where the key is 'LocationName' and the value is the name of a location.
  Future<List<Map<String, dynamic>>> getLocationNames() async {
    final Database db = await this.db;
    return await db.query('Locations', columns: ['LocationName']);
  }

  /// Provides a list of location name suggestions based on the provided query.
  ///
  /// The function fetches all location names from the 'Locations' table and filters them based on the provided query.
  /// It returns a list of up to 3 location names that start with the query string.
  ///
  /// [query] The string based on which location name suggestions are to be provided.
  ///
  /// Returns a list of location name suggestions.
  Future<List<String>> getSuggestions(String query) async {
    List<Map<String, dynamic>> locationNames = await getLocationNames();
    List<String> suggestions = [];

    for (var location in locationNames) {
      if (location['LocationName'].toLowerCase().startsWith(query.toLowerCase())) {
        suggestions.add(location['LocationName']);
        if (suggestions.length == 3) {
          break;
        }
      }
    }

    return suggestions;
  }

  /// Fetches the forecast for a given location.
  ///
  /// @param query The name of the location to fetch the forecast for.
  /// @return A Future that completes with a list of maps. Each map represents a row from the 'PredictedSeaConditions' and 'computedseaconditions' tables.
  Future<List<Map<String, dynamic>>> fetchForecast(String query) async {
    final Database db = await this.db;
    List<Map<String, dynamic>> locationNames = await db.query('Locations', columns: ['LocationID', 'LocationName']);
    dynamic locationId;
    
    for (var location in locationNames) {
      if (location['LocationName'] == query) {
        locationId = location['LocationID'];
        break;
      }
    }

    // If locationId is not found, handle the situation (e.g., return an empty list)
    if (locationId == null) {
      return [];
    }

    var now = DateTime.now();
    var todayMidnight = DateTime(now.year, now.month, now.day);
    var threeDaysFromNow = todayMidnight.add(const Duration(days: 3));
    print('Locationnnn! $locationId');
    try {
      var connection = await openConnection();
      print('has connection!');

      // // Executing the query
      final results = await connection.query(
        'SELECT * FROM PredictedSeaConditions WHERE LocationID = @locationId AND Date >= @todayMidnight AND Date < @threeDaysFromNow',
        substitutionValues: {
          "locationId":  locationId,
          "todayMidnight": todayMidnight.toIso8601String(),
          "threeDaysFromNow": threeDaysFromNow.toIso8601String(),
        },
      );

      final results2 = await connection.query(
        'SELECT * FROM computedseaconditions WHERE LocationID = @locationId AND TimeOfDay >= @todayMidnight AND TimeOfDay < @threeDaysFromNow',
        substitutionValues: {
          "locationId":  locationId,
          "todayMidnight": todayMidnight.toIso8601String(),
          "threeDaysFromNow": threeDaysFromNow.toIso8601String(),
        },
      );
  
      // Extracting rows from the Result object
      List<Map<String, dynamic>> rows = [];
      List<Map<String, dynamic>> rows2 = [];
      List<Map<String, dynamic>> combinedRows = [];
      for (var row in results) {
        var map = <String, dynamic>{};
        for (var i = 0; i < row.length; i++) {
          map[results.columnDescriptions[i].columnName] = row[i];
        }
        rows.add(map);
      }

      // Process results from second query
      for (var row in results2) {
        var map = <String, dynamic>{};
        for (var i = 0; i < row.length; i++) {
          map[results2.columnDescriptions[i].columnName] = row[i];
        }
        rows2.add(map);
      }
      await connection.close();
       print('closed connection!');
      // Combine rows safely using the smaller list length
      int minLength = rows.length < rows2.length ? rows.length : rows2.length;
      for (var i = 0; i < minLength; i++) {
        Map<String, dynamic> combinedRow = {...rows2[i], ...rows[i]};
        combinedRows.add(combinedRow);
      }

      // Add any remaining elements from the longer list

      combinedRows.sort((a, b) {
        final dateComparison = a['date'].compareTo(b['date']);
        if (dateComparison != 0) {
          return dateComparison;
        } else {
          return a['timeofday'].compareTo(b['timeofday']);
        }
      });

      print(combinedRows);
      return combinedRows;
    } catch (e) {
      print('Failed to fetch forecast: $e');
      return [];
    }
  }

  Future<PostgreSQLConnection> openConnection() async {
    var connection = PostgreSQLConnection(
      "",5432,"",
      queryTimeoutInSeconds: 3600,
      timeoutInSeconds: 3600,
      username: "",
      password: ""
    );
    await connection.open();

    return connection;
  }

  /// Fetches the most searched localization by a specific user from the database.
  ///
  /// If no search history exists for the given userID, returns null.
  Future<String> getMostSearchedLocalization(int userID) async {
    final Database db = await this.db;

    // Query to get the most searched localization by the user
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SearchTerm, COUNT(SearchTerm) AS count
      FROM searchHistory
      WHERE userID = ? AND deletedAt IS NULL
      GROUP BY SearchTerm
      ORDER BY count DESC
      LIMIT 1
    ''', [userID]);

    // If there's a result, return the most searched localization, else return null
    if (result.isNotEmpty) {
      return result.first['SearchTerm'];
    } else {
      return '';
    }
  }

  /// Synchronizes local changes with the server.
  Future<void> syncWithServer() async {
    final Database localDb = await db;
    final PostgreSQLConnection serverDb = await openConnection();

    // Sync bidirectionaly changes with local
    await syncUserBidirectional(localDb, serverDb);
    // await syncSearchHistoriesWithLocal(localDb, serverDb);
    await syncCardBidirectional(localDb, serverDb);

    // Close server connection
    await serverDb.close();
    print('Synced changes bidirectionally with server');
  }

  /// Synchronize user data from the local database with the server
  Future<void> syncUserBidirectional(Database localDb, PostgreSQLConnection serverDb) async {
    try {
      var localUsers = await localDb.query('users');
      var serverUsers = await serverDb.query('SELECT * FROM users');
      List<User> serverUserObjects = [];
      print('serverUsers');
      // Convert the maps to User objects
      List<User> localUserObjects = localUsers.map((user) => User.fromMap(user)).toList();
      if (serverUsers.isNotEmpty) {
        serverUserObjects = serverUsers.map((userMap) => User.fromMap({
          'id':userMap[0],
          'userEmail': userMap[1],
          'hashedPassword': userMap[2],
          'salt': userMap[3],
          'userPreferences': '',
          'createdAt': userMap[5]?.toIso8601String(),
          'updateddAt': userMap[6]?.toIso8601String(),
          'deletedAt': userMap[7]?.toIso8601String(),
          'isThirdParty': userMap[8] == 1,
        })).toList();
      }

      // Sync local users to server
      for (User localUser in localUserObjects) { 
        User? existingServerUser = serverUserObjects.firstWhereOrNull((u) => u.userEmail == localUser.userEmail);
        final userId = await getUserIDByEmail(localUser.userEmail);
        if (existingServerUser != null) {
          // If local version is newer, update server user
          if (localUser.updatedAt.isAfter(existingServerUser.updatedAt)) {
            await serverDb.query(
              """
              UPDATE users
              SET hashedPassword = @hashedPassword, salt = @salt, userPreferences = @userPreferences, createdAt = @createdAt, updatedAt = @updatedAt, deletedAt = @deletedAt, isThirdParty = @isThirdParty
              WHERE userEmail = @userEmail
              """,
              substitutionValues: localUser.toMap(),
            );
          } 
          // If server version is newer, update local user
          else if (localUser.updatedAt.isBefore(existingServerUser.updatedAt)) {
            await localDb.update(
              'users',
              existingServerUser.toMap(),
              where: "userEmail = ?",
              whereArgs: [existingServerUser.userEmail],
            );
          }
        } else {
          print('No existing putin to SERVER');
          // Insert new server user
          await serverDb.query(
            """
            INSERT INTO users (userID, userEmail, hashedPassword, salt, userPreferences, createdAt, updatedAt, deletedAt, isThirdParty)
            VALUES (@userID, @userEmail, @hashedPassword, @salt, @userPreferences, @createdAt, @updatedAt, @deletedAt, @isThirdParty)
            """,
            substitutionValues: {
               "userID": userId,
              ...localUser.toMap(),
            }
          );
        }
      }

      // Sync server users to local
      for (var serverUser in serverUserObjects) {
        User? existingLocalUser = localUserObjects.firstWhereOrNull((u) => u.userEmail == serverUser.userEmail);

        if (existingLocalUser == null) {
            print('No existing putin to LOCAL');
          // Insert new local user
          await localDb.insert(
            'users',
            serverUser.toMap(),
          );
        }
      }
    } catch (e) {
      print('Error syncing user data between local database and server: $e');
    }
  }

  /// Synchronize user data from the local database with the server
  Future<void> syncCardBidirectional(Database localDb, PostgreSQLConnection serverDb) async {
    try {
      var localCards = await localDb.query('creditCard');
      var serverCards = await serverDb.query('SELECT * FROM creditCard');

      // Convert the maps to CreditCard objects
      List<CreditCard> localCardObjects = localCards.map((card) => CreditCard.fromMap(card)).toList();
      List<CreditCard> serverCardObjects = serverCards.map((cardMap) => CreditCard.fromMap({
        'userID': cardMap[0],
        'lastDigits': cardMap[1],
        'expiryDate': cardMap[2],
        'subscriptionId': cardMap[3],
        'createdAt': cardMap[4]?.toIso8601String(),
        'updatedAt': cardMap[5]?.toIso8601String(),
        'deletedAt': cardMap[6]?.toIso8601String(),
      })).toList();

      // Sync local cards to server
      for (CreditCard localCard in localCardObjects) {
        CreditCard? existingServerCard = serverCardObjects.firstWhereOrNull((c) => c.subscriptionId == localCard.subscriptionId);
        List<Map<String, dynamic>> queryResult = await localDb.query(
          'CreditCard',
          where: "subscriptionId = ?",
          whereArgs: [localCard.subscriptionId],
        );

        int userID = queryResult.first['userID'];

        if (existingServerCard != null) {
          // If local version is newer, update server card
          if (localCard.updatedAt!.isAfter(existingServerCard.updatedAt!)) {
            await serverDb.query(
              """
              UPDATE creditCard
              SET lastDigits = @lastDigits, expiryDate = @expiryDate, subscriptionId = @subscriptionId =, updatedAt = @updatedAt
              WHERE subscriptionId = @subscriptionId
              """,
              substitutionValues: localCard.toMap(userID),
            );
          } 
          // If server version is newer, update local card
          else if (localCard.updatedAt!.isBefore(existingServerCard.updatedAt!)) {
            await localDb.update(
              'creditCard',
              existingServerCard.toMap(userID),
              where: "userID = ?",
              whereArgs: [existingServerCard],
            );
          }
        } else {
          // Insert new server card
          await serverDb.query(
            """
            INSERT INTO creditCard (userID, lastDigits, expiryDate, updatedAt, subscriptionId)
            VALUES (@userID, @lastDigits, @expiryDate, @updatedAt, @subscriptionId)
            """,
            substitutionValues: localCard.toMap(userID),
          );
        }
      }
      // Sync server cards to local
      for (var serverCard in serverCardObjects) {
        CreditCard? existingLocalCard = localCardObjects.firstWhereOrNull((c) => c.subscriptionId == serverCard.subscriptionId);

        if (existingLocalCard == null) {
          var userID = await serverDb.query(
            'SELECT userID FROM creditCard WHERE subscriptionId = @subscriptionId',
            substitutionValues: {
              'subscriptionId': serverCard.subscriptionId,
            }
          );

          // Insert new local card
          await localDb.insert(
            'creditCard',
            serverCard.toMap(userID.first.first),
          );
        }
      }
    } catch (e) {
      print('Error syncing card data between local database and server: $e');
    }
  }
}