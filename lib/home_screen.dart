import 'package:flutter/material.dart';
import 'package:uts/api/api_service.dart';
import 'package:uts/model/provinsi.dart';
import 'package:uts/model/weather.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';
import 'dart:core';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Provinsi> _provinsiList = [];
  Provinsi? _selectedProvinsi;
  Weather? _weather;
  Area? _selectedArea;
  bool _isLoading = false;
  String? _error;

  ScrollController _scrollController = ScrollController();
  bool _showLeftShadow = false;
  bool _showRightShadow = true;

  @override
  void initState() {
    super.initState();
    _loadProvinsi();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _showLeftShadow = _scrollController.offset > 0;
      _showRightShadow =
          _scrollController.position.maxScrollExtent > _scrollController.offset;
    });
  }

  void _loadProvinsi() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final provinsiList = await _apiService.getProvinsi();
      setState(() {
        _provinsiList = provinsiList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading provinsi: $e';
        _isLoading = false;
      });
      print(_error);
    }
  }

  void _loadWeather(String provinsi) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _weather = null;
      _selectedArea = null;
    });
    try {
      final weather = await _apiService.getWeather(provinsi);
      setState(() {
        _weather = weather;
        _isLoading = false;
        if (_weather!.areas.isNotEmpty) {
          _selectedArea = _weather!.areas.first;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading weather: $e';
        _isLoading = false;
      });
      print(_error);
    }
  }

  String _getIndonesianDayName(DateTime date) {
    switch (DateFormat('EEEE').format(date)) {
      case 'Monday':
        return 'Senin';
      case 'Tuesday':
        return 'Selasa';
      case 'Wednesday':
        return 'Rabu';
      case 'Thursday':
        return 'Kamis';
      case 'Friday':
        return 'Jumat';
      case 'Saturday':
        return 'Sabtu';
      case 'Sunday':
        return 'Minggu';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          'Menyala Cuacaku',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        )),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlue[200]!, Colors.lightBlue[50]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
                  child: DropdownButton<Provinsi>(
                    hint: Text('Pilih Provinsi'),
                    value: _selectedProvinsi,
                    isExpanded: true,
                    underline: SizedBox(),
                    onChanged: (Provinsi? newValue) {
                      setState(() {
                        _selectedProvinsi = newValue;
                        if (newValue != null) {
                          _loadWeather(newValue.id);
                        }
                      });
                    },
                    items: _provinsiList.map((Provinsi provinsi) {
                      return DropdownMenuItem<Provinsi>(
                        value: provinsi,
                        child: Text(provinsi.name),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (_weather != null) ...[
                Card(
                  color: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
                    child: DropdownButton<Area>(
                      hint: Text('Pilih Kab/Kota'),
                      value: _selectedArea,
                      isExpanded: true,
                      underline: SizedBox(),
                      onChanged: (Area? newValue) {
                        setState(() {
                          _selectedArea = newValue;
                        });
                      },
                      items: _weather!.areas.map((Area area) {
                        return DropdownMenuItem<Area>(
                          value: area,
                          child: Text(area.name),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red))
              else if (_selectedArea != null) ...[
                Center(
                  child: Text(
                    '${_selectedArea!.name}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                _buildWeatherInfoCard(),
                SizedBox(height: 20),
                _buildHourlyForecastList(),
                SizedBox(height: 20),
                SizedBox(height: 20),
                _buildTemperatureChart(),
                SizedBox(height: 10),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfoCard() {
    IconData weatherIcon;
    Color iconColor;
    String weatherCondition = _selectedArea!.currentWeatherCondition;
    DateTime now = DateTime.now();
    bool isNight = now.hour < 6 || now.hour >= 18;

    switch (weatherCondition) {
      case 'Hujan':
        weatherIcon = isNight ? WeatherIcons.night_rain : WeatherIcons.day_rain;
        iconColor = Colors.blue;
        break;
      case 'Berawan':
        weatherIcon =
            isNight ? WeatherIcons.night_cloudy : WeatherIcons.day_cloudy;
        iconColor = Colors.grey;
        break;
      case 'Berangin':
        weatherIcon = isNight ? WeatherIcons.windy : WeatherIcons.day_windy;
        iconColor = Colors.blueGrey;
        break;
      default:
        weatherIcon =
            isNight ? WeatherIcons.night_clear : WeatherIcons.day_sunny;
        iconColor = isNight ? Colors.indigo : Colors.orange;
    }
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(weatherIcon, size: 80, color: iconColor),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(
                          weatherCondition,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedArea!.currentTemperature}°C',
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Table(
              children: [
                _buildTableRow('Kelembapan',
                    '${_selectedArea!.currentHumidity}%', Icons.water_drop),
                _buildTableRow('Kecepatan Angin',
                    '${_selectedArea!.windSpeed} KPH', Icons.air),
                _buildTableRow(
                    'Arah Angin', _selectedArea!.windDirection, Icons.explore),
              ],
            ),
            Divider(),
            Table(
              children: [
                _buildTableRow('Suhu Max', '${_selectedArea!.maxTemperature}°C',
                    Icons.thermostat),
                _buildTableRow('Suhu Min', '${_selectedArea!.minTemperature}°C',
                    Icons.ac_unit),
                _buildTableRow('Kelembapan Max',
                    '${_selectedArea!.maxHumidity}%', Icons.water),
                _buildTableRow(
                    'Kelembapan Min',
                    '${_selectedArea!.minHumidity}%',
                    Icons.water_drop_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value, IconData icon) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(value, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ramalan Cuaca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Container(
            height: 220,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                setState(() {
                  _showLeftShadow = scrollNotification.metrics.pixels > 0;
                  _showRightShadow = scrollNotification.metrics.pixels <
                      scrollNotification.metrics.maxScrollExtent;
                });
                return true;
              },
              child: ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _showLeftShadow ? Colors.black : Colors.transparent,
                      Colors.transparent,
                      Colors.transparent,
                      _showRightShadow ? Colors.black : Colors.transparent,
                    ],
                    stops: [0.0, 0.1, 0.9, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstOut,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedArea!.hourlyForecasts.length,
                  itemBuilder: (context, index) {
                    var forecast = _selectedArea!.hourlyForecasts[index];
                    bool isNight = forecast.datetime.hour < 6 ||
                        forecast.datetime.hour >= 18;

                    String dayName = _getIndonesianDayName(forecast.datetime);

                    IconData weatherIcon;
                    Color iconColor;
                    switch (forecast.weatherCondition) {
                      case 'Hujan':
                        weatherIcon = isNight
                            ? WeatherIcons.night_rain
                            : WeatherIcons.day_rain;
                        iconColor = Colors.blue;
                        break;
                      case 'Berawan':
                        weatherIcon = isNight
                            ? WeatherIcons.night_cloudy
                            : WeatherIcons.day_cloudy;
                        iconColor = Colors.grey;
                        break;
                      case 'Berangin':
                        weatherIcon = isNight
                            ? WeatherIcons.windy
                            : WeatherIcons.day_windy;
                        iconColor = Colors.blueGrey;
                        break;
                      default:
                        weatherIcon = isNight
                            ? WeatherIcons.night_clear
                            : WeatherIcons.day_sunny;
                        iconColor = isNight ? Colors.indigo : Colors.orange;
                    }

                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dayName,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(DateFormat('HH:mm').format(forecast.datetime)),
                            SizedBox(height: 5),
                            Icon(weatherIcon, size: 30, color: iconColor),
                            SizedBox(height: 5),
                            Text(forecast.weatherCondition,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('${forecast.temperature}°C'),
                            Text('${forecast.humidity}%'),
                            Text(forecast.windDirection),
                            Text('${forecast.windSpeed} KPH'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ))
      ],
    );
  }

  Widget _buildTemperatureChart() {
    final double itemWidth = 80;
    final double chartWidth = _selectedArea!.hourlyForecasts.length * itemWidth;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ramalan Suhu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: 260,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: chartWidth,
                  child: Column(
                    children: [
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getTemperatureSpots(),
                                isCurved: true,
                                color: Colors.indigo,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.indigo,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems:
                                    (List<LineBarSpot> touchedBarSpots) {
                                  return touchedBarSpots.map((barSpot) {
                                    final flSpot = barSpot;
                                    return LineTooltipItem(
                                      '${flSpot.y.toStringAsFixed(1)}°C',
                                      TextStyle(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: (FlTouchEvent event,
                                  LineTouchResponse? touchResponse) {},
                              handleBuiltInTouches: true,
                            ),
                            minX: -0.5,
                            maxX: _selectedArea!.hourlyForecasts.length
                                    .toDouble() -
                                0.5,
                            minY: _getMinTemperature() - 1,
                            maxY: _getMaxTemperature() + 3,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 60,
                        child: Row(
                          children: _selectedArea!.hourlyForecasts
                              .asMap()
                              .entries
                              .map((entry) {
                            var forecast = entry.value;
                            String dayName =
                                _getIndonesianDayName(forecast.datetime)
                                    .substring(0, 3);
                            return Container(
                              width: itemWidth,
                              child: Column(
                                children: [
                                  Text(
                                    dayName,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(forecast.datetime),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.indigo),
                                  ),
                                  Text(
                                    '${forecast.windSpeed.toStringAsFixed(1)} km/j',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.indigo),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getTemperatureSpots() {
    return _selectedArea!.hourlyForecasts
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.temperature))
        .toList();
  }

  double _getMinTemperature() {
    return _selectedArea!.hourlyForecasts.map((f) => f.temperature).reduce(min);
  }

  double _getMaxTemperature() {
    return _selectedArea!.hourlyForecasts.map((f) => f.temperature).reduce(max);
  }
}
