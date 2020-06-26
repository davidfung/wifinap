import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

class AboutPage extends StatefulWidget {
  static const String routeName = '/about';
  static const String title = 'About';

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AboutPage.title),
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(
                    vertical: 30.0, horizontal: 30.0),
                children: <Widget>[
                  SectionWidget(
                    sectionTitle: "WHY",
                    sectionBody:
                        "How many times do you forget to turn WiFi back on after you turn it off due to a weak signal or privacy reasons?  It ends up using your data plan for a long time.",
                  ),
                  SectionWidget(
                    sectionTitle: "WiFi Nap",
                    sectionBody:
                        "This app will disable WiFi and automatically re-enable it shortly after.",
                  ),
                  SectionWidget(
                    sectionTitle: "VERSION",
                    sectionBody:
                        snapshot.data.version + '+' + snapshot.data.buildNumber,
                  ),
                  FeedbackWidget(),
                ],
              ),
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }
}

class SectionWidget extends StatelessWidget {
  const SectionWidget({
    Key key,
    @required this.sectionTitle,
    @required this.sectionBody,
  }) : super(key: key);

  final String sectionTitle;
  final String sectionBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(sectionTitle, style: captionStyle),
        Padding(
          padding: EdgeInsets.only(top: 7),
        ),
        Text(sectionBody, style: bodyStyle),
        Padding(
          padding: EdgeInsets.only(top: 30),
        ),
      ],
    );
  }
}

class FeedbackWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('FEEDBACK', style: captionStyle),
        Padding(
          padding: EdgeInsets.only(top: 7),
        ),
        InkWell(
            onTap: () {
              _launchURL();
            },
            child: Text('Visit amg99.com', style: linkStyle)),
      ],
    );
  }

  void _launchURL() async {
    const url = aboutUrl;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
