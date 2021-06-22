import 'package:flutter/material.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/screens/profile/profile_screen.dart';
import 'patient_list.dart';
import 'home_screen.dart';

// ignore: must_be_immutable
class StaffBottomNavScreen extends StatefulWidget {
  int nextScreen;
  StaffBottomNavScreen({Key key, @required this.nextScreen}) : super(key: key);

  @override
  _StaffBottomNavScreenState createState() =>
      _StaffBottomNavScreenState(nextScreen: this.nextScreen);
}

class _StaffBottomNavScreenState extends State<StaffBottomNavScreen> {
  int nextScreen;

  _StaffBottomNavScreenState({@required this.nextScreen});

  final List _screens = [
    StaffDashboardScreen(),
    RecentScans(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[nextScreen],
      backgroundColor: Colors.transparent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: nextScreen,
        onTap: (index) => setState(() => nextScreen = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.white,
        unselectedItemColor: kPrimaryColor,
        elevation: 0.0,
        items: [Icons.home, Icons.recent_actors_rounded, Icons.person]
            .asMap()
            .map((key, value) => MapEntry(
                  key,
                  BottomNavigationBarItem(
                    label: '',
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: nextScreen == key ? kPrimaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Icon(value),
                    ),
                  ),
                ))
            .values
            .toList(),
      ),
    );
  }
}
