import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/helper/APIService.dart';
import 'package:traciex/helper/SharedPreferencesHelper.dart';
import 'package:traciex/models/QRCode.dart';
import 'package:traciex/screens/default_test_location/default_test_location_screen.dart';
import 'package:traciex/screens/home/custom_app_bar.dart';
import 'package:traciex/screens/home/staff/register/patient_qr_scanner.dart';

class StaffDashboardScreen extends StatefulWidget {
  @override
  _StaffDashboardScreenState createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  QRCode myCode;
  String total = "0", used = "0", scrapped = "0";
  @override
  void initState() {
    super.initState();
    SharedPreferencesHelper.getMyQR().then((value) => {
          this.setState(() {
            myCode = value;
          })
        });
    final now = DateTime.now();
    APIService apiService = new APIService();
    String startDate = dateFormat.format(now);
    apiService.getStaffUsageReport(startDate, startDate).then((value) {
      if (value != null) {
        this.setState(() {
          total = value["total_kits"].toString();
          used = value["kits_assigned"].toString();
          scrapped = value["kits_scrapped"].toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: CustomAppBar(),
        body: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: <Widget>[
            buildHeader(screenHeight),
            buildTogether(screenHeight, 0.14),
            buildPreventionTips(screenHeight, 0.14),
            buildStatsHeader('My Usage Report'),
            buildStatsTabBar((startDate, endDate) {
              APIService apiService = new APIService();
              apiService.getStaffUsageReport(startDate, endDate).then((value) {
                if (value != null) {
                  this.setState(() {
                    total = value["total_kits"].toString();
                    used = value["kits_assigned"].toString();
                    scrapped = value["kits_scrapped"].toString();
                  });
                }
              });
            }),
            StatsGrid(total: total, used: used, scrapped: scrapped)
          ],
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: () async {
            String locationId = await SharedPreferencesHelper.getString(
                "DefaultTestLocationId");

            if (locationId == null || locationId == "-1") {
              Toast.show("Please select the Default Test Location", context,
                  duration: kToastDuration, gravity: Toast.BOTTOM);
              Timer(Duration(seconds: kToastDuration), () {
                Navigator.pushNamed(context, DefaultTestLocation.routeName);
              });
            } else {
              Navigator.pushNamed(context, ScanPatientQRCode.routeName);
            }
          },
          child: Icon(
            Icons.qr_code_scanner_sharp,
            color: Colors.white,
            size: 29,
          ),
          backgroundColor: kPrimaryColor,
          tooltip: 'Scan patient QR and device barcode',
          elevation: 5,
          splashColor: Colors.grey,
        ));
  }
}
