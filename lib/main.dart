import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}
class _WeatherAppState extends State<WeatherApp> {
  int         temperature;
  String      location          = 'New Delhi';
  int         woeid             = 28743736;
  String      weather           = "clear";
  String      searchApiURl      = 'https://www.metaweather.com/api/location/search/?query=';
  String      locationApiURL    = 'https://www.metaweather.com/api/location/';
  String      abbrev            = '';
  var         abbrevForecast       = new List(7);
  String      errorMsg          = '';

  var minTempForecast           = new List(7);
  var maxTempForecast           = new List(7);

  Position    _currentPosition;
  String      _currentAddress;

  Future fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiURl + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location    = result['title'];
        woeid       = result['woeid'];
        errorMsg    = '';
      });
    }
    catch(exception){
      setState(() {
        errorMsg = 'City not found! Please try something else.';
      });
    }
  }

  Future fetchLocation() async {
    var searchResult   = await http.get(Uri.parse(locationApiURL + woeid.toString()));
    var result         = json.decode(searchResult.body);
    var allWeatherData = result["consolidated_weather"];
    var data           = allWeatherData[0];

    setState(() {
      temperature     = data["the_temp"].round();
      weather         = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbrev          = data['weather_state_abbr'];
    });
  }

  Future fetchWeatherDay() async {
    var today   = DateTime.now();
    
    for(var i=0; i<7; i++){
      var locationByDay   = await http.get(Uri.parse(locationApiURL + woeid.toString() + '/' + new DateFormat('y/M/d').format(today.add(new Duration(days: i+1))).toString()));
      var result          = json.decode(locationByDay.body);
      var data            = result[0];

      setState(() {
        minTempForecast[i]    = data["min_temp"].round();
        maxTempForecast[i]    = data["max_temp"].round();
        abbrevForecast[i]     = data["weather_state_abbr"];
      });
    }
  }

  //**** User's location related functions *******/
  _getCurrentLocation() {
  Geolocator
    .getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true)
      .then((Position position) {
        setState(() {
          _currentPosition = position;
          _getAddressFromLatLong();
          //getWeatherOfLocation(_currentAddress);
        });
      }).catchError((error) {
        setState(() {
          errorMsg = error;
        });
    });
  }

  _getAddressFromLatLong() async {
    try{
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude,
        _currentPosition.longitude
      );

      Placemark place = placemarks[0];

      setState(() {
        //_currentAddress = "${place.locality}, ${place.postalCode}, ${place.country}";
        _currentAddress = "${place.locality}";
      });
    }
    catch(e){
      print(e);
    }
  }
  //**** User's location related functions end *******/

  Future<void> getWeatherOfLocation(String location) async {
    await fetchSearch(location);
    await fetchLocation();
    await fetchWeatherDay();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //onLocationSubmitted(location);
    fetchLocation();    //Called with default values
    fetchWeatherDay();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Weather UI",
      home: Container(
        decoration: BoxDecoration(
          //color: Color.alphaBlend(Colors.redAccent, Colors.blueAccent)
            image: DecorationImage(
              image: AssetImage(
                  'images/$weather.png'
              ),
              fit: BoxFit.cover,
              colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
            ),
        ),
        child: temperature == null
            ? Center(child: CircularProgressIndicator( color: Colors.white,))
            : Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child:
                  GestureDetector(
                    onTap: (){
                      _getCurrentLocation();
                      fetchSearch(_currentAddress);
                      //getWeatherOfLocation(_currentAddress);
                    },
                    child: Icon(Icons.location_pin, size: 25.0),
                  ),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  Center(
                    child: Image.network(
                        'https://www.metaweather.com/static/img/weather/png/' + abbrev + '.png',
                      width: 100,
                    ),
                  ),
                  Center(
                    child: Text(
                      temperature == null ? Center(child: CircularProgressIndicator( color: Colors.white,)) : temperature.toString() + "°c",
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontSize: 60,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      location == null ? Center(child: CircularProgressIndicator( color: Colors.white,)) : location,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget> [
                    for (var cnt=0; cnt<7; cnt++)
                      forecastElement(location.toString(),
                          cnt,
                          abbrevForecast[cnt].toString(),
                          minTempForecast[cnt].toString(),
                          maxTempForecast[cnt].toString(),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 300,
                    child: TextField(
                      onSubmitted: (String input){
                        getWeatherOfLocation(input);
                      },
                      style: TextStyle(
                        color: Colors.white, fontSize: 18.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search another location...',
                        hintStyle: TextStyle(color: Colors.white, fontSize: 16.0),
                        prefix: Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                  Text(
                    errorMsg,
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: Platform.isAndroid ? 17.0 : 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _currentPosition == null
                      ? Text('Update your location',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Platform.isAndroid ? 17.0 : 20,
                          fontWeight: FontWeight.w300,
                        ),
                      )
                      : Text(
                    'Location: ${_currentAddress}',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Platform.isAndroid ? 17.0 : 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget forecastElement(loc,daysFromNow, forecastAbb, minTemperature, maxTemperature){
  var now                 = new DateTime.now();
  var oneDayFromNow       = now.add(new Duration(days: daysFromNow));

  return Padding(
    padding: const EdgeInsets.only(left: 5.0, right: 5.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(loc,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Text(new DateFormat.E().format(oneDayFromNow),
            style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              new DateFormat.MMMd().format(oneDayFromNow),
                style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 15.0, left: 18.0, right: 18.0),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' + forecastAbb + '.png',
              width: 50,
              ),
            ),
            Text(
              'Min: '+ minTemperature.toString() + "°c",
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w300),
            ),
            Text(
              'Max: '+ maxTemperature.toString() + "°c",
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    ),
  );
}