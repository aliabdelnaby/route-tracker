import 'dart:convert';

import 'package:route_tracker/models/place_autocomplete_model/place_autocomplete_model.dart';
import 'package:http/http.dart' as http;

class GoogleMapsPlaceService {
  final String baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey = 'AIzaSyB7cXZs7rYf0S9yBpZn0q9QpKfU5CpK5z8';
  Future<List<PlaceModel>> getPredictions({required String input}) async {
    var response = await http.get(
      Uri.parse(
        '$baseUrl/autocomplete/json?key=$apiKey&input=$input',
      ),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['predictions'];
      List<PlaceModel> places = [];
      for (var item in data) {
        places.add(PlaceModel.fromJson(item));
      }
      return places;
    } else {
      throw Exception();
    }
  }
}