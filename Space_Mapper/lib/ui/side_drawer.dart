import 'dart:convert';
import 'package:asm/models/list_view.dart';
import 'package:asm/ui/list_view.dart';
import 'package:asm/ui/report_an_issue.dart';
import 'package:asm/ui/web_view.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class ShareLocation {
  late final String _timestamp;
  final double _lat;
  final double _long;

  ShareLocation(timestamp, this._lat, this._long) {
    _timestamp = CustomLocationsManager.formatTimestamp(timestamp);
  }

  Map<String, dynamic> toJson() => {
        'timestamp': _timestamp,
        'coords': {
          'latitude': _lat,
          'longitude': _long,
        }
      };
}

class SpaceMapperSideDrawer extends StatelessWidget {
  _shareLocations() async {
    var now = new DateTime.now();
    List allLocations = await bg.BackgroundGeolocation.locations;
    List<ShareLocation> customLocation = [];

    for (var thisLocation in allLocations) {
      ShareLocation _loc = new ShareLocation(
          bg.Location(thisLocation).timestamp,
          bg.Location(thisLocation).coords.latitude,
          bg.Location(thisLocation).coords.latitude);
      customLocation.add(_loc);
    }

    String text = jsonEncode(customLocation);
    /*for (var thisLocation in customLocation) {
      text += jsonEncode(thisLocation);
    }*/
    String subject =
        "space_mapper_trajectory_" + now.toIso8601String() + ".json";
    Share.share(text, subject: subject);
  }

  _launchProjectURL() async {
    const url = 'http://activityspaceproject.com/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 100,
            child: DrawerHeader(
              child: Text('Space Mapper Menu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              decoration: BoxDecoration(
                color: Colors.blueGrey[200],
              ),
            ),
          ),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text('Take survey'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyWebView()));
                  })),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list),
              title: Text('Locations History'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => STOListView()));
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share),
              title: Text('Share Locations'),
              onTap: () {
                _shareLocations();
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.web),
              title: Text('Visit Project Website'),
              onTap: () {
                _launchProjectURL();
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: Text('Report an Issue'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ReportAnIssue()));
              },
            ),
          )
        ],
      ),
    );
  }
}
