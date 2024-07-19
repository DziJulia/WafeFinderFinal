import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wavefinder/components/autobomplete_input.dart';
import 'package:wavefinder/components/custom_data_cell.dart';
import 'package:wavefinder/components/decorate_data_cell.dart';
import 'package:wavefinder/components/functions.dart';
import 'package:wavefinder/components/wave_chart.dart';
import 'package:wavefinder/config/database_helper.dart';
import 'package:wavefinder/config/user_session.dart';
import 'package:wavefinder/constants/platform.dart';
import 'package:wavefinder/not_found_location.dart';
import 'package:wavefinder/select_location.dart';
import 'package:wavefinder/theme/colors.dart';
import 'components/bubbles.dart';
import 'components/responsive_menu.dart';
import 'package:collection/collection.dart';

/// DashboardScreen widget displays the main interface for the WaveFinder application.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _controller = TextEditingController();
  String? userEmail;
  Map<String, bool> cardExpansionStates = {};

  /// Fetches search suggestions based on the user input query.
  Future<List<String>> getSuggestions(String query) async {
    bool isSubscribed = await DBHelper().hasSubscription(userEmail!);
    if (isSubscribed) {
      return await DBHelper().getSuggestions(query);
    }
    return [];
  }

  /// Fetches forecast data for a given location query.
  Future<List<Map<String, dynamic>>> fetchForecast(String query) async {
    return await DBHelper().fetchForecast(query);
  }

  /// Toggles the expanded state of a forecast card based on the date.
  void toggleDateExpansion(String date) {
    setState(() {
      cardExpansionStates.update(date, (value) => !value, ifAbsent: () => true);
      // Untoggle the rest
      cardExpansionStates.updateAll((key, value) => key != date ? false : value);
    });
  }

  /// Resets all card expansion states to false.
  void resetCardExpansionStates() {
    setState(() {
      cardExpansionStates = {};
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchTextChanged);
    _initializeController();
  }

  /// Initializes the search controller with the most searched location if the user is subscribed.
  void _initializeController() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userEmail = Provider.of<UserSession>(context, listen: false).userEmail;
      bool isSubscribed = await DBHelper().hasSubscription(userEmail!);
      String? searchedLocalization = isSubscribed ? await mostSearched(userEmail!) : '';
      setState(() {
        _controller.text = searchedLocalization;
      });
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Handles search text changes, updates forecasts and resets card expansion states.
  void _onSearchTextChanged() async {
    bool isSubscribed = await DBHelper().hasSubscription(userEmail!);
    if (isSubscribed) {
      await fetchForecast(_controller.text);
      await onSearch(_controller.text, userEmail!);
      resetCardExpansionStates();
      setState(() {});
    }
  }

  /// Builds the main content of the dashboard based on the forecast data.
  Widget buildDashboardContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchForecast(_controller.text),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (_controller.text.isEmpty) {
          return const SelectLocationMessage();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          // Return a CircularProgressIndicator while waiting for data
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          var groupedByDate = groupBy(snapshot.data as List<Map<String, dynamic>>, (row) => row['date'] != null ? row['date'].toLocal().toString().split(' ')[0] : '');
          if (groupedByDate.isEmpty) {
            return const NotFoundLocationMessage();
          }
          return SizedBox(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedByDate.entries.map<Widget>((entry) {
                    String date = formatDate(entry.key.toString());
                    String mostCommonRecommendation = findMostCommonRecommendation(entry.value);
                    List<Map<String, dynamic>> filteredRows = entry.value.where((row) => filterLogic(row, cardExpansionStates)).toList();

                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              toggleDateExpansion(date);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text(
                                    cardExpansionStates[date] ?? false ? '⬇️' : '➡️',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  Text(
                                    ' $date - $mostCommonRecommendation',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataTable(
                            columnSpacing: 11.0,
                            headingRowHeight: 30,
                            headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.grey;
                                }
                                return ThemeColors.bubblesColor;
                              },
                            ),
                            showBottomBorder: true,
                            columns: const <DataColumn>[
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('Surf Diff')),
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('Rating')),
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('            Wave', textAlign: TextAlign.center)),
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('            Swell', textAlign: TextAlign.center)),
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('     Wind', textAlign: TextAlign.center)),
                              DataColumn(label: Text('')),
                              DataColumn(label: Text('Weather')),
                            ],
                            rows: filteredRows.map<DataRow>((row) {
                              return DataRow(
                                cells: <DataCell>[
                                  DataCell(Text(getTimeString(int.parse(row['timeofday'].split(':')[0])))),
                                  DataCell(Container(
                                    margin: const EdgeInsets.only(top: 9, bottom: 9),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: separatorColor(row),
                                          width: 4.0,
                                        ),
                                      ),
                                    ),
                                  )),
                                  DataCell(Text('${row['surfdifficulty']}')),
                                  const DataCell(DecoratedDataCell()),
                                  DataCell(Text('${row['wavequality']}', style: TextStyle(color: separatorColor(row), fontWeight: FontWeight.bold))),
                                  const DataCell(DecoratedDataCell()),
                                  DataCell(CustomDataRow(param1: row['waveheight'], param2: row['wavedirection'], param3: row['waveperiod'])),
                                  const DataCell(DecoratedDataCell()),
                                  DataCell(CustomDataRow(param1: row['swellwaveheight'], param2: row['swellwavedirection'], param3: row['swellwaveperiod'])),
                                  const DataCell(DecoratedDataCell()),
                                  DataCell(
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text('${double.parse(row['windspeed']).toStringAsFixed(2)} km'),
                                        const SizedBox(width: 20),
                                        Text('${row['winddirection']}'),
                                      ],
                                    ),
                                  ),
                                  const DataCell(DecoratedDataCell()),
                                  DataCell(Text('${double.parse(row['weather']).toStringAsFixed(2)} °C')),
                                ],
                              );
                            }).toList(),
                          ),
                          if (cardExpansionStates[date] ?? false)
                            SizedBox(
                              height: 250,
                              width: 800,
                              child: WaveChart(waveData: filteredRows),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    userEmail = Provider.of<UserSession>(context).userEmail;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          PositionedBubble(),
          ListView(
            children: <Widget>[
              const ResponsiveMenu(),
              SizedBox(height: isMobile ? 90 : 0),
              AutocompleteInputField(
                hintText: 'Search location',
                getSuggestions: getSuggestions,
                onSelected: (String selection) {
                  _controller.text = selection;
                  _onSearchTextChanged();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  _controller.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FutureBuilder<bool>(
                future: DBHelper().hasSubscription(userEmail!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    if (snapshot.data!) {
                      return buildDashboardContent();
                    } else {
                      _controller.text = '';
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Subscribe now for exclusive content and premium features!',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Image.asset('assets/images/subscribe.png'),
                          ],
                        ),
                      );
                    }
                  } else {
                    return Column(
                      children: [
                        const Text(
                          'Oops! Something went wrong while fetching subscription status.',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Image.asset('assets/images/warning.png'),
                      ],
                    );
                  }
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
