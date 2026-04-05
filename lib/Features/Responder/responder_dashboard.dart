import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:fortress/Common%20Widgets/constants.dart';
import 'package:fortress/Features/User/Screens/LiveStreaming/sos_page.dart';
import 'package:fortress/Features/User/Screens/Profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_switch/sliding_switch.dart';
import 'package:url_launcher/url_launcher.dart';
import '../User/Controllers/message_sending.dart';
import '../User/Screens/LiveStreaming/live_stream.dart';
import 'dart:math';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({Key? key}) : super(key: key);
  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  final activeSOSRef = FirebaseDatabase.instance.ref().child('sos');
  final activeRespondersRef = FirebaseDatabase.instance.ref().child('activeResponders');
  final userRef = FirebaseDatabase.instance.ref().child('Users');
  
  String userType = '';
  Position? currentPosition;
  String status = 'Unavailable';
  bool _switchValue = false;
  double alertRadius = 15.0; // KM radius for alerts

  @override
  void initState() {
    super.initState();
    _loadSwitchValue();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {});
  }

  Future<void> _loadSwitchValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _switchValue = prefs.getBool('switchValue') ?? false;
      status = _switchValue ? 'Available' : 'Unavailable';
    });
  }

  Future<void> _saveSwitchValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switchValue', value);
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(color),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: Colors.white24, width: 4)),
        onPressed: () => Get.to(() => const ProfileScreen()),
        child: const Icon(Icons.person),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      appBar: AppBar(
        backgroundColor: Color(color),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Get.height * 0.16),
          child: Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              children: [
                Image(image: const AssetImage("assets/logos/emergencyAppLogo.png"), height: Get.height * 0.07),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Responder Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SlidingSwitch(
                    value: _switchValue,
                    width: 100.0,
                    onChanged: (value) {
                      setState(() {
                        _saveSwitchValue(value);
                        _switchValue = value;
                        status = value ? 'Available' : 'Unavailable';
                        updateResponderStatus(value);
                      });
                    },
                    height: 40.0,
                    textOff: 'OFF',
                    textOn: 'ON',
                    onTap: () {},
                    onDoubleTap: () {},
                    onSwipe: () {},
                    colorOn: Colors.green,
                    colorOff: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: activeSOSRef.onValue,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> sosMap = snapshot.data!.snapshot.value as Map;
            List<Map<String, dynamic>> items = [];

            sosMap.forEach((key, value) {
              if (currentPosition != null) {
                double dist = calculateDistance(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                  double.parse(value['lat'].toString()),
                  double.parse(value['long'].toString()),
                );
                
                if (dist <= alertRadius) {
                  var item = Map<String, dynamic>.from(value);
                  item['distance'] = dist;
                  item['id'] = key;
                  items.add(item);
                }
              }
            });

            if (items.isEmpty) {
              return const Center(child: Text("No Nearby Emergencies", style: TextStyle(fontSize: 18, color: Colors.grey)));
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: ListTile(
                    tileColor: Color(color),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    onTap: () => launchMap(item['lat'], item['long']),
                    title: Text(item['address'] ?? 'Emergency Request', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('Distance: ${item['distance'].toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white),
                        IconButton(
                          icon: const Icon(Icons.video_call, color: Colors.red, size: 30),
                          onPressed: () => Get.to(() => LiveStreamingPage(liveId: item['videoId'], isHost: false)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void launchMap(lat, long) async {
    String url = "https://www.google.com/maps/search/?api=1&query=$lat,$long";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void updateResponderStatus(bool active) async {
    if (active) {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      activeRespondersRef.child(user!.uid).set({
        "lat": pos.latitude.toString(),
        "long": pos.longitude.toString(),
        "responderID": user!.uid,
      });
    } else {
      activeRespondersRef.child(user!.uid).remove();
    }
  }
}
