///CardTypes for displaying the item
enum CardType { 
  visa, 
  mastercard,
  other
}

/// Sanitizes an email input.
///
/// This function trims leading and trailing whitespace from the input
/// and checks if the input matches a basic email pattern.
///
/// Throws a [FormatException] if the input does not match the email pattern.
///
/// Returns the sanitized input if it is a valid email.
///
/// [value] is the email input to be sanitized.
String sanitizeInput(String value) {
  // Add your sanitization logic here
  // For example, you might want to remove leading and trailing whitespaces
  String sanitizedValue = value.trim();

  // Validate the email format
  String p = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
  RegExp regExp = RegExp(p);

  if (regExp.hasMatch(sanitizedValue)) {
    // If the email format is valid, return the sanitized value
    return sanitizedValue;
  } else {
    // If the email format is invalid, return a specific string
    return 'Invalid email format';
  }
}

/// Validates the given password based on several criteria.
///
/// The password must be at least 8 characters long, contain at least one lowercase letter,
/// one uppercase letter, one number, and one special character.
///
/// [value] is the password string to be validated.
///
/// Returns a string containing an error message if the password does not meet the criteria.
/// If the password is valid, it returns null.
String? validatePassword(String? value) {
  //print(value);
  if (value == null || value.isEmpty) {
    return  'Please enter a password';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Must contain at least one lowercase letter';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Must contain at least one uppercase letter';
  }
  if (!RegExp(r'\d').hasMatch(value)) {
    return 'Must contain at least one number';
  }
  if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
    return 'Must contain at least one special character';
  }

  return null;
}

/// Checks if a card number is valid based on its length and card type (Visa or MasterCard).
///
/// @param value The card number as a string.
/// @return `true` if the card number is valid, `false` otherwise.
bool validateCardNumber(String value) {
  final visaPattern = RegExp(r'^4[0-9]{12}(?:[0-9]{3})?$');
  final mastercardPattern = RegExp(r'^(5[1-5][0-9]{14}|2(22[1-9][0-9]{12}|2[3-9][0-9]{13}|[3-6][0-9]{14}|7[0-1][0-9]{13}|720[0-9]{12}))$');

  if (visaPattern.hasMatch(value) || mastercardPattern.hasMatch(value)) {
    return true;
  } else {
    return false;
  }
}