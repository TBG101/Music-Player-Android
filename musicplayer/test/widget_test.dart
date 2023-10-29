// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_test/flutter_test.dart';

void main() async {
  var uri = Uri.https(
      "youtube-search-results.p.rapidapi.com", "youtube-search", {"q": "move"});

  var response = await http.get(uri, headers: {
    'X-RapidAPI-Key': 'a1db472272msh381390d8c748bf0p123c89jsnc292e2863054',
    'X-RapidAPI-Host': 'youtube-search-results.p.rapidapi.com'
  });
  List x = jsonDecode(response.body)["videos"];
}
