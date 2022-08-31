// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables

import 'package:effektio/common/widget/customAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/AppCommon.dart';

class SocialProfileScreen extends StatefulWidget {
  const SocialProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  _SocialProfileScreenState createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final _client = ModalRoute.of(context)!.settings.arguments as Client;
    return Scaffold(
      appBar: AppBar(
        title: navBarTitle('Social Profile'),
        elevation: 1,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Container(
                margin: const EdgeInsets.only(bottom: 10, left: 10),
                child: Image.asset(
                  'assets/images/hamburger.png',
                  color: AppCommonTheme.svgIconColor,
                ),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 10),
              child: Image.asset(
                'assets/images/edit.png',
                color: AppCommonTheme.svgIconColor,
              ),
            ),
            onPressed: () {
              setState(() {});
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 15, left: 20, right: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  width: double.infinity,
                  height: 230,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/images/profileBack.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 50,
                  top: 40,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 100,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: AppCommonTheme.primaryColor,
                              width: 5,
                            ),
                          ),
                          child: CustomAvatar(
                            avatar: _client.avatar(),
                            displayName: _client.displayName(),
                            isGroup: false,
                            stringName: '',
                            radius: 60,
                          ),
                        ),
                        const Text(
                          'Harjeet kAUR',
                          style: SideMenuAndProfileTheme.profileNameStyle,
                        ),
                        const Text(
                          'Harjeet@gmail.com',
                          style: SideMenuAndProfileTheme.profileUserIdStyle,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            SizedBox(
              height: 25,
            ),
            DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TabBar(
                    tabs: [
                      Tab(
                        child: Text(
                          'News',
                          style: SideMenuAndProfileTheme.profileMenuStyle,
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Feed',
                          style: SideMenuAndProfileTheme.profileMenuStyle,
                        ),
                      ),
                      Tab(
                        child: Text(
                          'More details',
                          style: SideMenuAndProfileTheme.profileMenuStyle,
                        ),
                      ),
                    ],
                    indicatorColor: AppCommonTheme.primaryColor,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height - 100,
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        Text(''),
                        Text(''),
                        Text(''),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
