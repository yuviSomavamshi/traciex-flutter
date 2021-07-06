import 'package:flutter/material.dart';
import 'package:traciex/models/Location.dart';
import 'package:traciex/size_config.dart';

class LocationDropDown extends StatelessWidget {
  final List<Location> locations;
  final String title;
  final String location;
  final Function(String) onChanged;

  const LocationDropDown({
    this.title = "Location",
    @required this.locations,
    @required this.location,
    @required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(title,
            style: TextStyle(
                fontSize: getProportionateScreenWidth(20),
                color: Colors.black)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: location,
            items: locations
                .map((e) => DropdownMenuItem(
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.location_pin),
                          const SizedBox(width: 8.0),
                          Text(
                            e.location,
                            style: TextStyle(
                                fontSize: getProportionateScreenWidth(16)),
                          )
                        ],
                      ),
                      value: e.id,
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        )
      ],
    );
  }
}
