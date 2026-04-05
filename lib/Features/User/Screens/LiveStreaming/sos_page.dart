import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:fortress/Features/User/Controllers/session_controller.dart';
import 'package:fortress/Common%20Widgets/constants.dart';
import 'package:fortress/Features/Emergency%20Contacts/emergency_contacts_controller.dart';
import 'package:fortress/Features/User/Controllers/message_sending.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveStreamUser extends StatefulWidget {
  const LiveStreamUser({Key? key}) : super(key: key);

  @override
  State<LiveStreamUser> createState() => _LiveStreamUserState();
}

class _LiveStreamUserState extends State<LiveStreamUser> {
  final sessionController = Get.put(SessionController());
  final smsController = Get.put(MessageController());
  final contactController = Get.put(EmergencyContactsController());

  @override
  void initState() {
    super.initState();
    smsController.handleLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(Get.height * 0.1),
            child: Container(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                          image: const AssetImage(
                              "assets/logos/emergencyAppLogo.png"),
                          height: Get.height * 0.08),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "SOS",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )),
      ),
      body: Stack(
        children: [
          Container(color: Colors.black12),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SOS Button
                  SizedBox(
                    width: Get.width * 0.7,
                    height: Get.width * 0.7,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 20,
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        shadowColor: Colors.redAccent,
                      ),
                      onPressed: () async {
                        final userId = sessionController.userid;
                        if (userId == null) {
                          Get.snackbar("Error", "User session not found. Please log in again.");
                          return;
                        }

                        // Send distress message directly, without navigating to Live Stream
                        smsController.sendLocationViaSMS("General Emergency - SOS triggered");
                        
                        // Save location to DB
                        saveCurrentLocation();
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
                          Text("SOS", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  const Text(
                    "Press the button to send your location to your emergency contacts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Manual Share Button as backup
                  OutlinedButton.icon(
                    onPressed: () async {
                      final userId = sessionController.userid;
                      if (userId != null) {
                        Position pos = await Geolocator.getCurrentPosition();
                        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
                        String _currentAddress = "${placemarks[0].street}, ${placemarks[0].locality}";
                        String message = "HELP! Emergency!\n"
                          "Map: http://www.google.com/maps/place/${pos.latitude},${pos.longitude}\n"
                          "Address: $_currentAddress";
                        
                        final Uri smsLaunchUri = Uri(
                          scheme: 'sms',
                          path: '',
                          queryParameters: <String, String>{
                            'body': message,
                          },
                        );
                        
                        if (await canLaunchUrl(smsLaunchUri)) {
                          await launchUrl(smsLaunchUri);
                        } else {
                          Get.snackbar("Error", "Could not launch SMS app for manual sharing.");
                        }
                      } else {
                        Get.snackbar("Error", "User session not found.");
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("Share Location Manually"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  saveCurrentLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final ref = FirebaseDatabase.instance.ref("sos/${user.uid.toString()}");
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then((position) async {
        await placemarkFromCoordinates(position.latitude, position.longitude)
            .then((List<Placemark> placemarks) {
          Placemark place = placemarks[0];
          String address =
              '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
          ref.set({
            "time": "${DateTime.now().hour}:${DateTime.now().minute} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
            "address": address,
            "email": user.email.toString(),
            "lat": position.latitude.toString(),
            "long": position.longitude.toString(),
            "videoId": user.uid.toString(),
          });
        });
      });
    } catch (e) {
      debugPrint("Error saving location: $e");
    }
  }
}
