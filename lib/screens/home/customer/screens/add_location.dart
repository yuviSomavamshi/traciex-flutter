import 'package:flutter/material.dart';
import 'package:traciex/helper/APIService.dart';
import 'package:traciex/helper/keyboard.dart';
import 'package:traciex/components/default_button.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/screens/home/custom_app_bar.dart';
import 'package:traciex/screens/home/home_screen.dart';
import 'package:traciex/size_config.dart';
import 'package:toast/toast.dart';

class RegisterLocation extends StatelessWidget {
  static String routeName = "/registerLocation";
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: CustomAppBar(),
        body: CustomScrollView(
            physics: ClampingScrollPhysics(),
            slivers: <Widget>[
              buildHeader(screenHeight),
              SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  sliver: SliverToBoxAdapter(
                      child: Column(
                    children: [
                      SizedBox(height: 20),
                      Text("Location Registration",
                          style: TextStyle(
                              fontSize: getProportionateScreenWidth(20),
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 30),
                      LocationRegForm()
                    ],
                  )))
            ]));
  }
}

class LocationRegForm extends StatefulWidget {
  @override
  _LocationRegFormState createState() => _LocationRegFormState();
}

class _LocationRegFormState extends State<LocationRegForm> {
  final _formKey = GlobalKey<FormState>();
  String _name;
  bool confirmation = false;
  bool buttonEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(10)),
          child: Column(
            children: [
              _buildFirstNameFormField(),
              SizedBox(height: getProportionateScreenHeight(20)),
              DefaultButton(
                text: "Register",
                press: () async {
                  KeyboardUtil.hideKeyboard(context);
                  if (_formKey.currentState.validate()) {
                    setState(() {
                      buttonEnabled = false;
                    });
                    APIService apiService = new APIService();
                    apiService.createLocation(_name).then((value) {
                      if (value != null) {
                        // if all are valid then go to success screen
                        if (value.statusCode == 200) {
                          Toast.show(
                              "Registered the Location successfully.", context,
                              duration: kToastDuration, gravity: Toast.BOTTOM);

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerHomeScreen(nextScreen: 2),
                              ));
                        } else if (value.message != null &&
                            value.message.isNotEmpty) {
                          setState(() {
                            buttonEnabled = true;
                          });
                          Toast.show(value.message, context,
                              duration: kToastDuration, gravity: Toast.BOTTOM);
                        }
                      }
                    });
                  }
                },
              ),
              SizedBox(height: getProportionateScreenHeight(20))
            ],
          ),
        ));
  }

  TextFormField _buildFirstNameFormField() {
    return TextFormField(
      maxLength: 25,
      onSaved: (newValue) => _name = newValue,
      onChanged: (value) {
        if (value.isNotEmpty) {
          _name = value;
        }
        return null;
      },
      validator: (value) {
        if (value.isEmpty) {
          return kLocationNameNullError;
        }
        if (value.isNotEmpty && value.length < 4) {
          return "Minimum 4 alphanumeric characters";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "Location name",
        hintText: "Enter location name",
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: Icon(Icons.location_pin),
      ),
    );
  }
}
