import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fortress/Features/User/Controllers/message_sending.dart';
import 'package:fortress/Features/User/Screens/User DashBoard/grid_dash.dart';

import '../../../../Common Widgets/constants.dart';
// import 'login_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestAllPermissions();
  }

  Future<void> _requestAllPermissions() async {
    // Request all required permissions after login when the dashboard loads
    await [
      Permission.location,
      Permission.sms,
    ].request();
    
    // Also use MessageController's specific handlers if needed
    MessageController().handleSmsPermission();
    MessageController().handleLocationPermission();
  }

  final _messageController = Get.put(MessageController());
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('DashBoard'),
      // ),

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
            preferredSize:  Size.fromHeight(Get.height * 0.1),
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
                          "Dashboard",
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

      body: Container(
        margin: EdgeInsets.only(top: Get.height * 0.1),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: GridDashboard(),
        ),
      ),
    );
  }
}
