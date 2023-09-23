import 'dart:convert';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter/material.dart';

import '../models/app_localizations.dart';
import '../components/banner_image.dart';
import '../components/project_tile.dart';
import '../mocks/mock_project.dart';
import '../models/project.dart';
import '../models/custom_locations.dart';
import '../styles.dart';
//import '../external_projects/tiger_in_car/models/participating_projects.dart';
//import '../db/database_project.dart';

const BannerImageHeight = 300.0;
const BodyVerticalPadding = 20.0;
const FooterHeight = 100.0;

class ProjectDetail extends StatefulWidget {
  final int projectID;

  ProjectDetail(this.projectID);

  @override
  _ProjectDetailState createState() => _ProjectDetailState(projectID);
}

class _ProjectDetailState extends State<ProjectDetail> {
  final int projectID;
  Project project = Project.blank();
  bool consent = false;
  int dropdownValue = 7;

  _ProjectDetailState(this.projectID);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              AppLocalizations.of(context)?.translate("about_the_project") ??
                  "")),
      body: Stack(
        children: [
          _renderBody(context, project),
          _renderFooter(context),
        ],
      ),
    );
  }

  loadData() {
    final project = MockProject.fetchByID(this.projectID);

    if (mounted) {
      setState(() {
        this.project = project;
        print('Fetched project details: ${project.name}');
      });
    }
  }

  Widget _renderBody(BuildContext context, Project project) {
    var result = <Widget>[];
    result.add(BannerImage(url: project.imageUrl, height: BannerImageHeight));
    result.add(_renderHeader());
    result.add(_renderConsentForm());
    if (consent) result.add(_renderFrequencyChooser());
    result.add(_renderBottomSpacer());
    return SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: result));
  }

  Widget _renderHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: BodyVerticalPadding,
          horizontal: Styles.horizontalPaddingDefault),
      child: ProjectTile(project: project, darkTheme: false),
    );
  }

  Widget _renderFooter(BuildContext contexty) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.5)),
          height: FooterHeight,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
            child: _renderParticipateInProjectButton(),
          ),
        )
      ],
    );
  }

  Widget _renderConsentForm() {
    print('Project name in _renderConsentForm: ${project.name}');
    String title =
        AppLocalizations.of(context)?.translate("consent_form") ?? "";
  /*  String text = AppLocalizations.of(context)
            ?.translate("do_you_agree_to_share_your_anonymous_location_with") ??
        "" + "${project.name}?";*/
String text = (AppLocalizations.of(context)
        ?.translate("do_you_agree_to_share_your_anonymous_location_with") ??
    "") + "${project.name}?";

    return Container(
      height: ProjectTileHeight,
      padding: EdgeInsets.symmetric(
          //vertical: BodyVerticalPadding,
          horizontal: Styles.horizontalPaddingDefault),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Styles.projectTileTitleLight),
          Row(
            children: [
              Checkbox(
                value: consent,
                onChanged: (bool? newValue) {
                  setState(() {
                    consent = newValue!;
                  });
                },
              ),
              Expanded(
                child: Text('$text',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: Styles.projectTileCaption),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderFrequencyChooser() {
    String title = "Days to share";

    return Container(
      height: ProjectTileHeight,
      padding: EdgeInsets.symmetric(
          //vertical: BodyVerticalPadding,
          horizontal: Styles.horizontalPaddingDefault),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Styles.projectTileTitleLight),
          DropdownButton(
            value: dropdownValue,
            onChanged: (int? newValue) {
              setState(() {
                dropdownValue = newValue!;
              });
            },
            items: <int>[7, 30, 365].map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text("$value"),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _renderParticipateInProjectButton() {
    return TextButton(
      //color: Styles.accentColor,
      //textColor: Styles.textColorBright,
      style: ButtonStyle(
                          backgroundColor: consent
                            ? MaterialStateProperty.all(Colors.blue)
                            : MaterialStateProperty.all(Colors.grey),  // Use grey color when consent is false
                          foregroundColor: consent
                            ? MaterialStateProperty.all(Colors.white)
                            : MaterialStateProperty.all(Colors.black),  // Use appropriate text color based on consent
                        ),      
      onPressed: consent ? () => 
        _navigationToProject(context) : null,
      
      child: Text(
        'Participate'.toUpperCase(),
        style: Styles.textCTAButton,
      ),
    );
  }


/*
//Buggy Participating 
  Widget _renderParticipateInProjectButton() {
    return FutureBuilder<bool>(
    future: checkParticipationStatus(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // Display a loader while checking status
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        bool isParticipating = snapshot.data ?? false;

        print('Particpation status : ${isParticipating}');

        return TextButton(
          style: ButtonStyle(
            backgroundColor: isParticipating
                ? MaterialStateProperty.all(Colors.grey)
                : MaterialStateProperty.all(Colors.blue),
            foregroundColor: isParticipating
                ? MaterialStateProperty.all(Colors.black)
                : MaterialStateProperty.all(Colors.white),
          ),
          onPressed: isParticipating ? null : () => _navigationToProject(context),
          child: Text(
            isParticipating ? 'Participating' : 'Participate'.toUpperCase(),
            style: Styles.textCTAButton,
          ),
        );
      }
    },
  );
}

  Future<bool> checkParticipationStatus() async {
    // Get the current date and time
    DateTime currentDate = DateTime.now();

    // Fetch the project details
    final project = await ProjectDatabase.instance.readProject(projectID);

    print('Project id : ${project.projectId}');
    print('Project id : ${project.startDate}');
    print('Project id : ${project.endDate}');

      if (project.projectId == -1) {
    // Allow participation if project ID is -1
    return false;
  }
  else
  {
    // Check if a record exists and if the current date and time are within the participation period
    if (currentDate.isAfter(project.startDate) && currentDate.isBefore(project.endDate)) {
      // The user is participating, disable the button and display "Participating"
      /*setState(() {
        consent = true;
        print('here?');
      });*/ //commented out because it causes a loop
      return true;
    } else {
      return false;
    }
  }
  }
*/
  Future<String> getLocationsToShare(int maxDays) async {
    if (!consent)
      return "I do not consent to share my location history.";
    else {
      String ret = "";
      DateTime now = DateTime.now();

      /// var difference = berlinWallFell.difference(moonLanding);
      /// assert(difference.inDays == 7416);
      List allLocations = await bg.BackgroundGeolocation.locations;
      List<ShareLocation> customLocation = [];

      for (var thisLocation in allLocations) {
        ShareLocation _loc = new ShareLocation(
            bg.Location(thisLocation).timestamp,
            bg.Location(thisLocation).coords.latitude,
            bg.Location(thisLocation).coords.longitude);

        // Filter locations to share based on the dates provided by the user
        var difference =
            now.difference(_loc.timestampToDateTime(_loc.getTimestamp()));
        if (difference.inDays <= maxDays)
          customLocation.add(_loc);
        else
          break;
      }

      ret = jsonEncode(customLocation);
      ret = ret.replaceAll("\"",
          "'"); //We replace " into ' to avoid a javascript exception when we post it in the webview's form

      return ret;
    }
  }


  Future<void> _navigationToProject(BuildContext context) async {
    String locationHistoryJSON = await getLocationsToShare(dropdownValue);

    project.participate(context, locationHistoryJSON);
  }

/*
  Future<void> _navigationToProject(BuildContext context) async {
    String locationHistoryJSON = await getLocationsToShare(dropdownValue);

    // Calculate enddate based on startdate and duration
    DateTime startDate = DateTime.now();
    DateTime endDate = startDate.add(Duration(days: dropdownValue));

    // Create a Project instance with the provided data
    Particpating_Project projectRecord = Particpating_Project(
      projectId: projectID,
      projectName: project.name,
      duration: dropdownValue,
      startDate: startDate,
      endDate: endDate,
    );

  // Insert the record into the database
  await ProjectDatabase.instance.createProject(projectRecord);

    project.participate(context, locationHistoryJSON);
  }
*/
  Widget _renderBottomSpacer() {
    return Container(height: FooterHeight);
  }
}
