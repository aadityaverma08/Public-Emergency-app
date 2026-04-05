import 'dart:io';

import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fortress/Features/User/Controllers/session_controller.dart';
import '../../Emergency Contacts/emergency_contacts_controller.dart';

class MessageController extends GetxController {
  static MessageController get instance => Get.find();
  final emergencyContactsController = Get.put(EmergencyContactsController());

  String? _currentAddress;
  Position? _currentPosition;
  Future<void> _sendSMS(String message, List<String> recipients) async {
    int sentCount = 0;
    for (var recipient in recipients) {
      try {
        SmsStatus status = await BackgroundSms.sendMessage(
          phoneNumber: recipient.trim(),
          message: message,
        );
        
        if (status == SmsStatus.sent) {
          sentCount++;
          debugPrint("SMS Sent successfully to $recipient");
        } else {
          debugPrint("Failed to send SMS to $recipient. Status: $status");
          Get.snackbar("SMS Error", "Failed to send alert to $recipient ($status)", 
            backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } catch (e) {
        debugPrint("Error sending SMS to $recipient: $e");
      }
    }
    
    if (sentCount > 0) {
      Get.snackbar("Emergency Alert", "Distress SMS Sent to $sentCount contact(s)",
        backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar("SMS Failed", "Could not send distress SMS to any contacts.",
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Disabled",
          'Location services are disabled. Please enable the services');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Rejected", 'Location Permissions are denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Rejected",
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  handleSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  Future<Position> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();

    if (!hasPermission) {
      return Future.error("Location permission denied");
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _currentPosition = position;
      await _getAddressFromLatLng(_currentPosition!);
      return _currentPosition!;
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to last known position
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _currentPosition = lastPosition;
        await _getAddressFromLatLng(_currentPosition!);
        return _currentPosition!;
      }
      return Future.error("Could not determine location");
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      _currentAddress =
          '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> sendLocationViaSMS(String emergencyType, [String? liveId]) async {
    final id = liveId ?? SessionController().userid ?? "unknown";

    // Request SMS permission
    bool hasSmsPermission = await handleSmsPermission();
    if (!hasSmsPermission) {
      Get.snackbar("Permission Denied", "SMS Permission is required to alert your contacts.");
      return;
    }
    
    try {
      debugPrint("Getting current position for SMS...");
      Position pos = await getCurrentPosition();
      
      // Ensure address is loaded
      if (_currentAddress == null) {
        await _getAddressFromLatLng(pos);
      }

      String message = "HELP! Emergency ($emergencyType)!\n"
          "Map: http://www.google.com/maps/place/${pos.latitude},${pos.longitude}\n"
          "Address: ${_currentAddress ?? 'Unknown Location'}";
      
      var emergencyContacts = await emergencyContactsController.loadData();
      List<String> validContacts = emergencyContacts.where((c) => c.trim().isNotEmpty).toList();
      
      if (validContacts.isNotEmpty) {
        await _sendSMS(message, validContacts);
      } else {
        Get.snackbar("No Contacts", "Add emergency contacts in settings to send alerts.");
      }
    } catch (e) {
      debugPrint("sendLocationViaSMS failed: $e");
      Get.snackbar("Error", "Could not fetch location to send SMS alerts.");
    }
  }
}
