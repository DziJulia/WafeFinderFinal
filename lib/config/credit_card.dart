class CreditCard {
  String lastFourDigits;
  String expiryDate;
  String subscriptionId;
  DateTime? updatedAt;
  DateTime? deletedAt;

  /// This is the constructor for the class. It initializes a new instance of the
  /// class with the given properties. The required keyword means that these
  /// properties must be provided when creating a new instance of the class.
  CreditCard(
    {
      required this.expiryDate,
      required this.lastFourDigits,
      required this.subscriptionId,
      this.updatedAt,
      this.deletedAt,
    }
  );

  /// This method converts the CreditCard object into a map, which can
  /// be used when inserting or updating records in the database.
  Map<String, dynamic> toMap(int userId) {
    return {
      'userID': userId,
      'lastDigits': lastFourDigits,
      'expiryDate': expiryDate,
      'subscriptionId': subscriptionId,
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// This method constructs a CreditCard object from a map.
  /// It takes a map as input and returns a CreditCard object.
  /// The map should contain keys for 'lastDigits', 'expiryDate',
  /// 'createdAt', 'updatedAt', and 'deletedAt'.
  /// 
  /// Example usage:
  /// 
  /// ```dart
  /// Map<String, dynamic> cardMap = {
  ///   'lastDigits': '1234',
  ///   'expiryDate': '12/25',
  ///   'createdAt': '2024-01-01T00:00:00Z',
  ///   'updatedAt': '2024-01-02T00:00:00Z',
  ///   'deletedAt': null,
  /// };
  /// CreditCard card = CreditCard.fromMap(cardMap);
  /// ```
  static CreditCard fromMap(Map<String, dynamic> map) {
    return CreditCard(
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      lastFourDigits: map['lastDigits'],
      expiryDate: map['expiryDate'],
      subscriptionId: map['subscriptionId'],
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }
}
