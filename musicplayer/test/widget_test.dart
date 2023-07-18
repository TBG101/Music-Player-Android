// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  // var result = await http.get(Uri.parse(
  //     "https://www.googleapis.com/youtube/v3/search?part=snippet&key=AIzaSyAww7JGtgWljnrXWdpRaf82Br3g8IwD_Ro&type=video&q=jelly"));
  // print(result.toString());
  // var x = await jsonDecode(result.body)['results'];
  // print("here");
  // print(x.toString());

  final response = await http
      .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

  print(response.body);
}
