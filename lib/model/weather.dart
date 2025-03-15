class Weather {
  final List<Area> areas;

  Weather({required this.areas});

  factory Weather.fromJson(Map<String, dynamic> json) {
    var forecastData = json['data']?['forecast'];
    if (forecastData == null) {
      throw FormatException('Invalid JSON format: missing forecast data');
    }

    var areasData = forecastData['area'];
    if (areasData == null || areasData is! List) {
      throw FormatException('Invalid JSON format: area data is not a list');
    }

    List<Area> areas =
        areasData.map((areaData) => Area.fromJson(areaData)).toList();
    return Weather(areas: areas);
  }
}

class Area {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<HourlyForecast> hourlyForecasts;
  final double currentTemperature;
  final double currentHumidity;
  final double windSpeed;
  final String windDirection;
  final double maxTemperature;
  final double minTemperature;
  final int maxHumidity;
  final int minHumidity;

  Area({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.hourlyForecasts,
    required this.currentTemperature,
    required this.currentHumidity,
    required this.windSpeed,
    required this.windDirection,
    required this.maxTemperature,
    required this.minTemperature,
    required this.maxHumidity,
    required this.minHumidity,
  });

  String get currentWeatherCondition {
    return HourlyForecast._determineWeatherCondition(
        currentTemperature, currentHumidity.round(), windSpeed);
  }

  factory Area.fromJson(Map<String, dynamic> json) {
    var parameters = json['parameter'] as List? ?? [];

    var temperatureData = _findParameter(parameters, 'Temperature');
    var humidityData = _findParameter(parameters, 'Humidity');
    var windSpeedData = _findParameter(parameters, 'Wind speed');
    var windDirectionData = _findParameter(parameters, 'Wind direction');
    var maxTempData = _findParameter(parameters, 'Max temperature');
    var minTempData = _findParameter(parameters, 'Min temperature');
    var maxHumidityData = _findParameter(parameters, 'Max humidity');
    var minHumidityData = _findParameter(parameters, 'Min humidity');

    List<HourlyForecast> hourlyForecasts = _createHourlyForecasts(
      temperatureData,
      humidityData,
      windDirectionData,
      windSpeedData,
    );

    return Area(
      id: json['id'] ?? '',
      name: json['description'] ?? '',
      latitude: double.tryParse(json['latitude'] ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude'] ?? '') ?? 0.0,
      hourlyForecasts: hourlyForecasts,
      currentTemperature: _parseFirstTimerangeValue(temperatureData),
      currentHumidity: _parseFirstTimerangeValue(humidityData),
      windSpeed: _parseFirstTimerangeValue(windSpeedData, valueIndex: 2),
      windDirection:
          _parseFirstTimerangeStringValue(windDirectionData, valueIndex: 1),
      maxTemperature: _parseFirstTimerangeValue(maxTempData),
      minTemperature: _parseFirstTimerangeValue(minTempData),
      maxHumidity: _parseFirstTimerangeValue(maxHumidityData).round(),
      minHumidity: _parseFirstTimerangeValue(minHumidityData).round(),
    );
  }

  static Map<String, dynamic> _findParameter(
      List parameters, String description) {
    return parameters.firstWhere(
      (param) => param['description'] == description,
      orElse: () => {'timerange': []},
    );
  }

  static double _parseFirstTimerangeValue(Map<String, dynamic> data,
      {int valueIndex = 0}) {
    var timerange = data['timerange'] as List? ?? [];
    if (timerange.isNotEmpty) {
      var values = timerange[0]['value'] as List? ?? [];
      if (values.length > valueIndex) {
        return double.tryParse(values[valueIndex]['text'] ?? '') ?? 0.0;
      }
    }
    return 0.0;
  }

  static String _parseFirstTimerangeStringValue(Map<String, dynamic> data,
      {int valueIndex = 0}) {
    var timerange = data['timerange'] as List? ?? [];
    if (timerange.isNotEmpty) {
      var values = timerange[0]['value'] as List? ?? [];
      if (values.length > valueIndex) {
        return values[valueIndex]['text'] ?? '';
      }
    }
    return '';
  }

  static List<HourlyForecast> _createHourlyForecasts(
    Map<String, dynamic> temperatureData,
    Map<String, dynamic> humidityData,
    Map<String, dynamic> windDirectionData,
    Map<String, dynamic> windSpeedData,
  ) {
    var tempTimerange = temperatureData['timerange'] as List? ?? [];
    var humidityTimerange = humidityData['timerange'] as List? ?? [];
    var windDirTimerange = windDirectionData['timerange'] as List? ?? [];
    var windSpeedTimerange = windSpeedData['timerange'] as List? ?? [];

    int minLength = [
      tempTimerange.length,
      humidityTimerange.length,
      windDirTimerange.length,
      windSpeedTimerange.length
    ].reduce((a, b) => a < b ? a : b);

    return List.generate(minLength, (index) {
      return HourlyForecast.fromJson(
        tempTimerange[index],
        humidityTimerange[index],
        windDirTimerange[index],
        windSpeedTimerange[index],
      );
    });
  }
}

class HourlyForecast {
  final DateTime datetime;
  final double temperature;
  final int humidity;
  final String windDirection;
  final double windSpeed;
  final String weatherCondition;

  HourlyForecast({
    required this.datetime,
    required this.temperature,
    required this.humidity,
    required this.windDirection,
    required this.windSpeed,
    required this.weatherCondition,
  });

  factory HourlyForecast.fromJson(
    Map<String, dynamic> tempJson,
    Map<String, dynamic> humidityJson,
    Map<String, dynamic> windDirJson,
    Map<String, dynamic> windSpeedJson,
  ) {
    String dateString = tempJson['datetime'] ?? '';
    DateTime dateTime = _parseDateTime(dateString);

    double temperature = _parseValue(tempJson, 0);
    int humidity = _parseValue(humidityJson, 0).round();
    double windSpeed = _parseValue(windSpeedJson, 2);

    String weatherCondition = _determineWeatherCondition(
      temperature,
      humidity,
      windSpeed,
    );

    return HourlyForecast(
      datetime: dateTime,
      temperature: temperature,
      humidity: humidity,
      windDirection: _parseStringValue(windDirJson, 1),
      windSpeed: windSpeed,
      weatherCondition: weatherCondition,
    );
  }

  static String _determineWeatherCondition(
      double temperature, int humidity, double windSpeed) {
    if (humidity > 80 && temperature < 30 && windSpeed > 5) {
      return 'Hujan';
    } else if (humidity > 50 &&
        humidity < 80 &&
        temperature < 30 &&
        temperature > 20 &&
        windSpeed > 10 &&
        windSpeed < 20) {
      return 'Berawan';
    } else if (windSpeed > 20) {
      return 'Berangin';
    } else {
      return 'Cerah';
    }
  }

  static DateTime _parseDateTime(String dateString) {
    try {
      return DateTime(
        int.parse(dateString.substring(0, 4)),
        int.parse(dateString.substring(4, 6)),
        int.parse(dateString.substring(6, 8)),
        int.parse(dateString.substring(8, 10)),
        int.parse(dateString.substring(10, 12)),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  static double _parseValue(Map<String, dynamic> json, int valueIndex) {
    var values = json['value'] as List? ?? [];
    if (values.length > valueIndex) {
      return double.tryParse(values[valueIndex]['text'] ?? '') ?? 0.0;
    }
    return 0.0;
  }

  static String _parseStringValue(Map<String, dynamic> json, int valueIndex) {
    var values = json['value'] as List? ?? [];
    if (values.length > valueIndex) {
      return values[valueIndex]['text'] ?? '';
    }
    return '';
  }
}
