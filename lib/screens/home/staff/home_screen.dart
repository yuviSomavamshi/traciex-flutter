import 'package:flutter/material.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/helper/APIService.dart';
import 'package:traciex/helper/SharedPreferencesHelper.dart';
import 'package:traciex/models/QRCode.dart';
import 'package:traciex/screens/home/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:traciex/screens/home/staff/register/patient_qr_scanner.dart';

class StaffDashboardScreen extends StatefulWidget {
  @override
  _StaffDashboardScreenState createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  QRCode myCode;
  DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
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
    String startDate = _dateFormat.format(now);
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
            buildTogether(screenHeight),
            buildPreventionTips(screenHeight),
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
          onPressed: () {
            Navigator.pushNamed(context, ScanPatientQRCode.routeName);
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
