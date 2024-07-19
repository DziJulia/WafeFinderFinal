class SearchHistory {
  final String searchTerm;
  DateTime? searchTime;
  final int userId;
  DateTime? deletedAt;

  /// This is the constructor for the class. It initializes a new instance of the
  /// class with the given properties. The required keyword means that these
  /// properties must be provided when creating a new instance of the class.
  SearchHistory({
    required this.userId,
    required this.searchTerm,
    this.searchTime,
    this.deletedAt,
  });

  /// This method converts the SearchHistory object into a map, which can
  /// be used when inserting or updating records in the database.
  Map<String, dynamic> toMap() {
    return {
      'userID': userId,
      'searchTerm': searchTerm,
      'searchTime': DateTime.now().toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}