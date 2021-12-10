import 'dart:convert';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../components/banner_image.dart';
import '../components/survey_tile.dart';
import '../mocks/mock_survey.dart';
import '../models/survey.dart';
import '../models/custom_locations.dart';
import '../ui/web_view.dart';
import '../styles.dart';

const BannerImageHeight = 300.0;
const BodyVerticalPadding = 20.0;
const FooterHeight = 100.0;

class SurveyDetail extends StatefulWidget {
  final int surveyID;

  SurveyDetail(this.surveyID);

  @override
  _SurveyDetailState createState() => _SurveyDetailState(surveyID);
}

class _SurveyDetailState extends State<SurveyDetail> {
  final int surveyID;
  Survey survey = Survey.blank();
  bool consent = false;
  int dropdownValue = 7;

  _SurveyDetailState(this.surveyID);

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
              AppLocalizations.of(context)!.translate("about_the_project"))),
      body: Stack(
        children: [
          _renderBody(context, survey),
          _renderFooter(context),
        ],
      ),
    );
  }

  loadData() {
    final survey = MockSurvey.fetchByID(this.surveyID);

    if (mounted) {
      setState(() {
        this.survey = survey;
      });
    }
  }

  Widget _renderBody(BuildContext context, Survey survey) {
    var result = <Widget>[];
    result.add(BannerImage(url: survey.imageUrl, height: BannerImageHeight));
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
      child: SurveyTile(survey: survey, darkTheme: false),
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
            child: _renderTakeSurveyButton(),
          ),
        )
      ],
    );
  }

  Widget _renderConsentForm() {
    String title = AppLocalizations.of(context)!.translate("consent_form");
    String text = AppLocalizations.of(context)!
            .translate("do_you_agree_to_share_your_anonymous_location_with") +
        "${survey.name}?";

    return Container(
      height: SurveyTileHeight,
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
              style: Styles.surveyTileTitleLight),
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
                    style: Styles.surveyTileCaption),
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
      height: SurveyTileHeight,
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
              style: Styles.surveyTileTitleLight),
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

  Widget _renderTakeSurveyButton() {
    return TextButton(
      //color: Styles.accentColor,
      //textColor: Styles.textColorBright,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.blue),
      ),
      onPressed: () => {
        _navigationToSurvey(context),
      },
      child: Text(
        'Take Survey'.toUpperCase(),
        style: Styles.textCTAButton,
      ),
    );
  }

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

  Future<void> _navigationToSurvey(BuildContext context) async {
    String locationHistoryJSON = await getLocationsToShare(dropdownValue);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MyWebView(survey.webUrl, locationHistoryJSON)));
  }

  Widget _renderBottomSpacer() {
    return Container(height: FooterHeight);
  }
}
