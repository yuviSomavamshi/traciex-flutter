import 'package:flutter/material.dart';

import 'package:traciex/constants.dart';
import 'package:traciex/size_config.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({Key key, this.text, this.press, this.enabled = true})
      : super(key: key);
  final String text;
  final Function press;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: getProportionateScreenHeight(56),
      child: ElevatedButton(
        onPressed: enabled ? press : null,
        style: ButtonStyle(
            backgroundColor: enabled
                ? MaterialStateProperty.all<Color>(kPrimaryColor)
                : MaterialStateProperty.all<Color>(kSecondaryColor)),
        child: Text(
          text,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: getProportionateScreenWidth(20),
              color: Colors.white),
        ),
      ),
    );
  }
}
