import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/helper/APIService.dart';
import 'package:traciex/helper/SharedPreferencesHelper.dart';
import 'package:traciex/models/QRCode.dart';
import 'package:traciex/screens/default_test_location/default_test_location_screen.dart';
import 'package:traciex/screens/home/custom_app_bar.dart';
import 'package:traciex/screens/home/home_screen.dart';
import 'package:traciex/screens/home/patient/screens/add_patient.dart';
import 'package:traciex/size_config.dart';
import 'package:toast/toast.dart';

APIService apiService = new APIService();

class PatientDashboardScreen extends StatefulWidget {
  @override
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  QRCode myCode;

  @override
  void initState() {
    super.initState();
    SharedPreferencesHelper.getMyQR().then((value) => {
          if (value != null)
            {
              this.setState(() {
                myCode = value;
              })
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
            buildPatientHeader(screenHeight, myCode, context),
            buildTogether(screenHeight, 0.14),
            buildPreventionTips(screenHeight, 0.14),
            _MyGrid()
          ],
        ));
  }
}

class _MyGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        sliver: SliverToBoxAdapter(
            child: Container(
          height: MediaQuery.of(context).size.height * 0.15,
          child: Column(
            children: <Widget>[
              Flexible(
                child: Row(
                  children: <Widget>[
                    _buildCard('my_staff', 'Register', context, 1)
                  ],
                ),
              ),
            ],
          ),
        )));
  }

  Expanded _buildCard(
      String image, String title, BuildContext context, int path) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10.0)),
        child: GestureDetector(
            onTap: () async {
              if (path == 1) {
                Navigator.pushNamedAndRemoveUntil(
                    context, RegisterPatient.routeName, (route) => true);
              } else {
                String locationId = await SharedPreferencesHelper.getString(
                    "DefaultTestLocationId");

                if (locationId == null || locationId == "-1") {
                  Toast.show("Please select the Default Test Location", context,
                      duration: kToastDuration, gravity: Toast.BOTTOM);
                  Timer(Duration(seconds: kToastDuration), () {
                    Navigator.pushNamed(context, DefaultTestLocation.routeName);
                  });
                }
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/images/' + image + '.png',
                    height: getProportionateScreenHeight(50),
                    width: getProportionateScreenWidth(50)),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: getProportionateScreenWidth(13),
                        color: kPrimaryColor))
              ],
            )),
      ),
    );
  }
}
