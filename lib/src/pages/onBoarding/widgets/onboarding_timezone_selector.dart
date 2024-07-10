import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:flutter/services.dart';
import '../../../../i18n/l10n.dart';
import '../../../../main.dart';
import '../../../data/countries.dart';

const platform = MethodChannel('nativeMethodsChannel');

class OnBoardingTimeZoneSelector extends StatefulWidget {
  final void Function()? onSelect;

  const OnBoardingTimeZoneSelector({Key? key, this.onSelect}) : super(key: key);

  @override
  _OnBoardingTimeZoneSelectorState createState() => _OnBoardingTimeZoneSelectorState();
}

class _OnBoardingTimeZoneSelectorState extends State<OnBoardingTimeZoneSelector> {
  late List<Country> countriesList;
  late List<String> selectedCountryTimezones;
  final TextEditingController searchController = TextEditingController();
  int selectedCountryIndex = -1;
  int selectedTimezoneIndex = -1;
  bool isViewingTimezones = false;

  @override
  void initState() {
    super.initState();
    countriesList = Countries.list;
    selectedCountryTimezones = [];
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      countriesList =
          Countries.list.where((country) => country.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).searchCountries),
          content: TextField(
            controller: searchController,
            onChanged: _filterItems,
            decoration: InputDecoration(
              hintText: S.of(context).searchCountries,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onSubmitted: (value) {
              _filterItems(value);
              Navigator.of(context).pop(); // Close the dialog when search is submitted
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).close),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog when search is submitted
              },
              child: Text(S.of(context).search),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            S.of(context).appTimezone,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.w700,
              color: themeData.brightness == Brightness.dark ? null : themeData.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            thickness: 1,
            color: themeData.brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
          const SizedBox(height: 10),
          Text(
            S.of(context).descTimezone,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: themeData.brightness == Brightness.dark ? null : themeData.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.focused)) {
                    return const Color(0xFF490094); // Focus color
                  }
                  return null; // Use the default color
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.focused)) {
                    return Colors.white; // Text and icon color when focused
                  }
                  return null; // Use the default color
                },
              ),
            ),
            onPressed: _showSearchDialog,
            icon: Icon(Icons.search),
            label: Text(S.of(context).searchCountries),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isViewingTimezones ? _buildTimezoneList(context) : _buildCountryList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryList(BuildContext context) {
    return ListView.builder(
      itemCount: countriesList.length,
      itemBuilder: (BuildContext context, int index) {
        var country = countriesList[index];
        return ListTile(
          tileColor: selectedCountryIndex == index ? const Color(0xFF490094) : null,
          title: Text(country.name),
          onTap: () {
            setState(() {
              selectedCountryIndex = index;
              selectedTimezoneIndex = -1;
              selectedCountryTimezones = country.timezones;
              isViewingTimezones = true;
            });
          },
        );
      },
    );
  }

  Widget _buildTimezoneList(BuildContext context) {
    return ListView.builder(
      itemCount: selectedCountryTimezones.length,
      itemBuilder: (BuildContext context, int index) {
        var timezone = selectedCountryTimezones[index];
        var location = tz.getLocation(timezone);
        var now = tz.TZDateTime.now(location);
        var timeZoneOffset = now.timeZoneOffset;
        return ListTile(
          tileColor: selectedTimezoneIndex == index ? const Color(0xFF490094) : null,
          title: Text('${_convertToGMTOffset(timeZoneOffset)} $timezone'),
          onTap: () async {
            setState(() {
              selectedTimezoneIndex = index;
            });
            await _setDeviceTimezone(timezone);
            widget.onSelect?.call();
          },
        );
      },
    );
  }

  Future<void> _setDeviceTimezone(String timezone) async {
    try {
      bool isSuccess = await platform.invokeMethod('setDeviceTimezone', {"timezone": timezone});
      if (isSuccess) {
        _showToast(S.of(context).timezoneSuccess);
      } else {
        _showToast(S.of(context).timezoneFailure);
      }
    } on PlatformException catch (e) {
      logger.e(e);
      _showToast(S.of(context).timezoneFailure);
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  String _convertToGMTOffset(Duration timeZoneOffset) {
    int totalMinutes = timeZoneOffset.inMinutes;
    String sign = totalMinutes >= 0 ? '+' : '-';
    int hours = totalMinutes.abs() ~/ 60;
    int minutes = totalMinutes.abs() % 60;
    return 'GMT$sign${_padZero(hours)}:${_padZero(minutes)}';
  }

  String _padZero(int value) => value < 10 ? '0$value' : '$value';
}
