import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uts/api/api_url.dart';
import 'package:uts/model/provinsi.dart';
import 'package:uts/model/weather.dart';

class ApiService {
  Future<List<Provinsi>> getProvinsi() async {
    final response = await http.get(Uri.parse(apiURL('provinsi')));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body)['data'];
      return jsonResponse.map((data) => Provinsi.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load provinsi');
    }
  }

  Future<Weather> getWeather(String provinsi) async {
    final response =
        await http.get(Uri.parse(apiURL('cuaca', provinsi: provinsi)));
    if (response.statusCode == 200) {
      var jsonBody = json.decode(response.body);
      if (jsonBody == null) {
        throw Exception('Empty response body');
      }
      return Weather.fromJson(jsonBody);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
}
