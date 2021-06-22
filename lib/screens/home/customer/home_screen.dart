import 'package:flutter/material.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/helper/APIService.dart';
import 'package:traciex/screens/home/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String total = "0", used = "0", scrapped = "0";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    APIService apiService = new APIService();
    String reportDate = dateFormat.format(now);
    apiService.getUsageReport(reportDate, reportDate).then((value) {
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
            buildStatsHeader('Usage Report'),
            buildStatsTabBar((startDate, endDate) {
              APIService apiService = new APIService();
              apiService.getUsageReport(startDate, endDate).then((value) {
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
        ));
  }
}
