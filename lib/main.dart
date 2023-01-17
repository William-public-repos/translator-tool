//Author: Phlus.com

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:translator/iso_codes.dart';
import 'package:translator/model.dart';
import 'package:translator/pop_menu.dart';
import 'package:translator/source.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Translation tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TranslatorPage(),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});
  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final FocusNode focusNode = FocusNode();
  FocusNode searchFocus = FocusNode();
  List<String> translated = [];
  Map<String, String> translatedmap = {};
  bool play = false;
  String selected = 'English';
  var apiKey = '';

  final keys = mapStrigns.keys;
  final values = mapStrigns.values;

  List<String> languages = isoLangs.values.toList();

  final languageKeys = isoLangs.keys.toList();

  Future<void> _translate() async {
    if (apiKey.isEmpty) {
      _showDialog(context);
      setState(() => play = false);
      return;
    }
    final language =
        languageKeys[languages.indexWhere((element) => element == selected)];

    if ((translated.length < values.length) && play) {
      await getTransalte(
              text: values.toList()[translated.length], target: language)
          .then((response) {
        if (response.statusCode == 200) {
          setState(() {
            translated.add(translationFromResponse(response.body).text);
            updateMap();
          });
        } else {
          _showInSnackBar(
              'Something is not right, make sure the selected language is not English and the Api key is not empty.',
              color: Colors.red);
          setState(() => play = false);
        }
      });
    }
    if (translated.length < values.length && play) {
      _translate();
    } else {
      if (play) {
        _showInSnackBar('Translated');
      }
      setState(() => play = false);
    }
  }

  void updateMap() {
    translated.asMap().forEach((index, value) =>
        translatedmap['"${keys.toList()[index]}"'] = '"$value"');
  }

  // Displays the popped String value in a SnackBar.
  void _showInSnackBar(String text, {Color? color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        padding: const EdgeInsets.all(20),
        backgroundColor: color,
        content: Text(text),
      ),
    );
  }

  Future<http.Response> getTransalte({
    required String text,
    required String target,
  }) async {
    //Source language is always English(en)
    var source = 'en';

    final response = await http.post(
      Uri.parse(
          'https://translation.googleapis.com/language/translate/v2?key=$apiKey'),
      body: {"q": text, "source": source, "target": target, "format": "text"},
    );

    return response;
  }

  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text))
        .then((value) => _showInSnackBar('Copied'));
  }

  void handleLanguageChanged(dynamic value) {
    setState(() {
      translated.clear();
      translatedmap.clear();
      selected = value ?? languages.first;
    });
  }

  Future<void> _showDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Missing Api key'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'Follow Instructions on README.md file in the root folder'),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _widgets() {
    List<Widget> response = [];
    translatedmap.forEach((key, value) {
      response.add(ListTile(
        title: Text('$key: $value,'),
      ));
    });
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.grey,
          // Here we take the value from the TranslatorPage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: SizedBox(
            width: 250,
            child: CustomPopupMenuButton(
              constraints: const BoxConstraints(
                  maxHeight: 400, maxWidth: 400, minWidth: 400),
              enableFeedback: true,
              onSelected: handleLanguageChanged,
              children: languages,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(20.0),
                ),
              ),
              // offset: const Offset(0, 50),
              child: ListTile(
                title: Text(selected),
                trailing: const Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                copyText(translatedmap.toString());
              },
              icon: const Icon(Icons.copy),
            )
          ],
        ),
        body: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    child: ListView(
                      shrinkWrap: true,
                      children: values.map((item) {
                        return ListTile(
                          title: Text(item),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Card(
                      margin: const EdgeInsets.all(20),
                      child: translated.isEmpty
                          ? const Center(
                              child: Text(
                                'No translations yet',
                                style: TextStyle(fontSize: 24),
                              ),
                            )
                          : SelectableRegion(
                              selectionControls: materialTextSelectionControls,
                              focusNode: focusNode,
                              child: ListView(children: _widgets()),
                            )),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (play) {
              setState(() => play = false);
            } else {
              setState(() => play = true);
              _translate();
            }
          },
          tooltip: play ? 'Stop' : 'Translate',
          child: play ? const Icon(Icons.stop) : const Icon(Icons.language),
        ));
  }
}
