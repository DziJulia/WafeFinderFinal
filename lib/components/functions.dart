import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/search_history.dart';

/// Returns a formatted string representing the time of day.
///
/// The time is given as an integer hour and the function returns a string
/// such as 'Midnight', '1am', '2pm', etc.
///
/// @param hour An integer representing the hour of the day (0-23).
/// @return A string representing the time in human-readable format.
String getTimeString(int hour) {
  if (hour == 0) {
    return 'Midnight';
  } else if (hour < 12) {
    return '${hour}am';
  } else if (hour == 12) {
    return 'Noon';
  } else {
    return '${hour - 12}pm';
  }
}

/// Returns a color based on the wave quality.
///
/// This function takes a map row containing wave quality and returns
/// a color representing the wave quality ('Excellent', 'Good', 'Fair', 'Poor').
///
/// @param row A map containing wave quality information.
/// @return A Color representing the wave quality.
Color separatorColor(row) {
  switch (row['wavequality']) {
    case 'Excellent':
      return Colors.green;
    case 'Good':
      return const Color.fromARGB(255, 178, 175, 0);
    case 'Fair':
      return Colors.orange;
    case 'Poor':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Checks if all values in the date map are false.
///
/// This function takes a map where the keys are date strings and the values are
/// booleans, and checks if all values are false.
///
/// @param date A map with date strings as keys and boolean values.
/// @return A boolean indicating whether all values in the map are false.
bool allFalseList(date) {
  bool allFalse;

  if (date == {}) {
    allFalse = false;
  } else {
    allFalse = date.values.every((v) => v == false);
  }

  return allFalse;
}

/// Finds the most common recommendation from a list of rows.
///
/// This function takes a list of maps where each map represents a row with a
/// recommendation and returns the most frequently occurring recommendation.
///
/// @param rows A list of maps containing recommendations.
/// @return A string representing the most common recommendation.
String findMostCommonRecommendation(List<Map<String, dynamic>> rows) {
  Map<String, int> recommendationCounts = {};

  for (var row in rows) {
    if (row['recommendation'] != null) {
      String recommendation = row['recommendation'];
      recommendationCounts[recommendation] = (recommendationCounts[recommendation] ?? 0) + 1;
    }
  }

  String mostCommonRecommendation = '';
  int maxCount = 0;
  recommendationCounts.forEach((recommendation, count) {
    if (count > maxCount) {
      mostCommonRecommendation = recommendation;
      maxCount = count;
    }
  });
  return mostCommonRecommendation;
}

/// Determines if a row should be displayed based on the filtering logic.
///
/// This function applies the filter logic to a row based on the hour of the day
/// and the card expansion states, and returns whether the row should be shown.
///
/// @param row A map containing information about a row, including the time of day and date.
/// @param cardExpansionStates A map representing whether each card is expanded or not.
/// @return A boolean indicating whether the row should be displayed.
bool filterLogic(Map<String, dynamic> row, Map<String, bool> cardExpansionStates) {
  int hour = int.parse(row['timeofday'].split(':')[0]);
  bool allFalse = allFalseList(cardExpansionStates);
  String formattedDate = DateFormat('dd/MM').format(row['date']);
  bool isExpanded = cardExpansionStates[formattedDate] ?? false;

  if(!allFalse) {
    if (isExpanded) {
      // If expanded, show every hour from 6 AM to 6 PM of the particular day
      return hour >= 6 && hour <= 18;
    } else {
      // If not expanded and nothing selected, show only the hours 6, 12, and 18 of all days
      return false;
    }
  } else {
    return hour == 6 || hour == 12 || hour == 18;
  }
}

String formatDate(String date) {
  List<String> parts = date.split('-');
  return '${parts[2]}/${parts[1]}';
}


Future<void> onSearch(String searchTerm, String userEmail) async {
  int userId = await DBHelper().getUserIDByEmail(userEmail);

  // Create a new SearchHistory object
  SearchHistory searchHistory = SearchHistory(
    userId: userId,
    searchTerm: searchTerm,
  );

  // Insert the search history into the database
  await DBHelper().insertSearchHistory(searchHistory);
}

Future<String> mostSearched(String userEmail) async {
  int userId = await DBHelper().getUserIDByEmail(userEmail);

  // Insert the search history into the database
  return await DBHelper().getMostSearchedLocalization(userId);
}

//For now im runing autodestroy on opening the app preferably i would like to move this to backround service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance instance) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await commonServiceFunction(instance);
  return true;
}

// Common function to be called by both onStart and onIosBackground
Future<void> commonServiceFunction(ServiceInstance instance) async {
  DBHelper dbHelper = DBHelper();
  // Run syncWithServer at startup
  await dbHelper.syncWithServer();

  // Periodically sync data with the server
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    print('UPDATE');
    // Run syncWithServer in the background
    await dbHelper.syncWithServer();
  });
}

// Function to handle periodic tasks in the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance instance) async {
  DartPluginRegistrant.ensureInitialized();
  await commonServiceFunction(instance);
}
