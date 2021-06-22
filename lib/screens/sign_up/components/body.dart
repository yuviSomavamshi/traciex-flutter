import 'package:flutter/material.dart';
import 'package:traciex/constants.dart';
import 'package:traciex/size_config.dart';

import 'sign_up_form.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  "assets/images/signup.png",
                  height: getProportionateScreenHeight(100),
                  width: getProportionateScreenWidth(100),
                ),
                Text("Register Account", style: headingStyle),
                Text(
                  "Complete your details and continue",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SizeConfig.screenHeight * 0.02),
                SignUpForm(),
                SizedBox(height: getProportionateScreenHeight(20)),
                Text(
                  'By continuing your confirm that you agree \nwith our Terms and Conditions',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
                Text("Secure Password Tips:"),
                Text(
                    "Use at least 8 characters, a combination of numbers, special characters and letters\n\t\t* at least one lowercase letter.\n\t\t* at least one uppercase letter.\n\t\t* at least one number.\n\t\t* at least one of these special characters !@#\$%^&\n\t",
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.caption)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
