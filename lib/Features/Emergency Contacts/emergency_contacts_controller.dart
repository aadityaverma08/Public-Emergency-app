import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactsController extends GetxController {
  static const String _key1 = 'contact1';
  static const String _key2 = 'contact2';
  static const String _key3 = 'contact3';
  static const String _key4 = 'contact4';
  static const String _key5 = 'contact5';

  Future<List<String>> loadData() async {
    var prefs = await SharedPreferences.getInstance();
    List<String> contacts = [];
    
    // Attempt to load all 5 contacts
    for (int i = 1; i <= 5; i++) {
        String key = "contact$i";
        String value = prefs.getString(key) ?? "";
        contacts.add(value.trim());
    }
    
    debugPrint("Emergency contacts loaded: ${contacts.join(', ')}");
    return contacts;
  }

  Future<void> setData(String contact1, String contact2, String contact3,
      String contact4, String contact5) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString(_key1, contact1);
    prefs.setString(_key2, contact2);
    prefs.setString(_key3, contact3);
    prefs.setString(_key4, contact4);
    prefs.setString(_key5, contact5);
  }
}
