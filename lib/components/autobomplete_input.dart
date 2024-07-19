import 'package:flutter/material.dart';
import 'package:wavefinder/constants/platform.dart';
import 'package:wavefinder/theme/colors.dart';

/// `AutocompleteInputField` is a widget that provides an autocomplete text field functionality.
/// It takes in parameters like hintText, getSuggestions function, fieldColor, and onSelected function.
class AutocompleteInputField extends StatefulWidget {
  final String hintText;
  final Future<List<String>> Function(String)? getSuggestions;
  final Color? fieldColor;
  final void Function(String)? onSelected;

  const AutocompleteInputField({
    super.key,
    this.fieldColor = ThemeColors.bubblesColor,
    required this.hintText,
    this.getSuggestions,
    this.onSelected,
  });

  @override
  AutocompleteInputFieldState createState() => AutocompleteInputFieldState();
}

class AutocompleteInputFieldState extends State<AutocompleteInputField> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = MediaQuery.of(context).size.width;
        final double inputWidth = isMobile ? maxWidth : (maxWidth > 1000) ? 600 : maxWidth * 0.6;

        return Center(
          child: SizedBox(
            width: inputWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 9),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '' || widget.getSuggestions == null) {
                    return const [];
                  }
                  return widget.getSuggestions!(textEditingValue.text);
                },
                onSelected: widget.onSelected,
                optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: Container(
                        height: 170,
                        width: 310,
                        color: widget.fieldColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return GestureDetector(
                              onTap: () => onSelected(option),
                              child: ListTile(
                                title: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: widget.fieldColor,
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                      suffixIcon: const Icon(Icons.search),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
