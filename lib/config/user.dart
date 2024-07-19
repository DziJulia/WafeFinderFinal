
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// `User` is a class that represents a user in the system.
///
/// Each user has the following properties:
/// - `userEmail`: The email address of the user.
/// - `hashedPassword`: The hashed version of the user's password.
/// - `salt`: The salt used in the password hashing process.
/// - `userPreferences`: The preferences set by the user.
/// - `createdAt`: The date and time when the user was created.
/// - `updatedAt`: The date and time when the user was last updated.
/// - `deletedAt`: The date and time when the user was deleted. This is nullable, meaning it can be null if the user is not deleted.
///
/// The constructor takes all these properties as parameters. All parameters are required except `deletedAt`, which is optional.
class User {
  String userEmail;
  late String hashedPassword;
  late String salt;
  String userPreferences;
  final DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
  bool isThirdParty; 

  /// This is the constructor for the class. It initializes a new instance of the
  /// class with the given properties. The required keyword means that these
  /// properties must be provided when creating a new instance of the class.
 User({
    required this.userEmail,
    required String password,
    required this.userPreferences,
    required this.createdAt,
    this.deletedAt,
    this.isThirdParty = false,
  }) {
    salt = generateSalt();
    hashedPassword = hashPassword(password, salt);
    updatedAt = DateTime.now();

  }

  /// Converts a User object into a map.
  ///
  /// This method is used when inserting or updating user data in the database.
  Map<String, dynamic> toMap() {
    updatedAt = DateTime.now(); 
    return {
      'userEmail': userEmail,
      'hashedPassword': hashedPassword,
      'salt': salt,
      'userPreferences': userPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'isThirdParty': isThirdParty ? 1 : 0,
    };
  }

  // Creates a User object from a map when fetching from DB
  static User fromMap(Map<String, dynamic> map) {
    return User(
      userEmail: map['userEmail'],
      password: map['hashedPassword'],
      userPreferences: map['userPreferences'],
      createdAt: DateTime.parse(map['createdAt']),
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
      isThirdParty:  map['isThirdParty'] == 1,
    )
    ..hashedPassword = map['hashedPassword']
    ..salt = map['salt'];
  }

  /// Hashes the user's password.
  ///
  /// This method generates a random salt and uses it to hash the user's password.
  /// The salt is then stored in the `salt` property of the `User` object.
  ///
  /// The hashed password is stored in the `hashedPassword` property of the `User` object.
  /// The original password is discarded to protect the user's security.
  ///   static String hashPassword(String password, [String? salt]) {
 static String hashPassword(String password, String salt) {
    var saltBytes = base64Url.decode(salt);
    var passwordBytes = utf8.encode(password);
    var hashBytes = sha256.convert([...saltBytes, ...passwordBytes]).bytes;

    return base64.encode(hashBytes);
  }

  static String generateSalt() {
    var rng = Random.secure();
    var saltBytes = List<int>.generate(16, (i) => rng.nextInt(256));

    return base64Url.encode(saltBytes);
  }

  /// Verifies a user's password.
  ///
  /// This method takes a plain text password, hashes it with the provided salt, 
  /// and compares it with the stored hashed password. If the hashed input password 
  /// matches the stored hashed password, it returns `true`, indicating that the 
  /// password is correct. Otherwise, it returns `false`.
  ///
  /// @param inputPassword The plain text password to verify.
  /// @param storedHashedPassword The hashed password stored in the database.
  /// @param salt The salt stored in the database for this user.
  /// @return A boolean indicating whether the input password is correct.
  static bool verifyPassword(String inputPassword, String storedHashedPassword, String salt) {
    var hashedInputPassword = hashPassword(inputPassword, salt);

    // print('hashedInputPassword');
    // print(hashedInputPassword);
    // print('storedHashedPassword');
    // print(storedHashedPassword);
    return hashedInputPassword == storedHashedPassword;
  }
}
