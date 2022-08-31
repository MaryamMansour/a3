// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/FaqListItem.dart';
import 'package:effektio/screens/EditorScreen/Editor.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class FaqOverviewScreen extends StatelessWidget {
  const FaqOverviewScreen({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListFaq>(
      future: client.faqs(),
      builder: (BuildContext context, AsyncSnapshot<FfiListFaq> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: AppCommonTheme.backgroundColor,
            child: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: AppCommonTheme.primaryColor,
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppCommonTheme.backgroundColor,
              title: Text(
                'Faq',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Container(
                    margin: const EdgeInsets.only(bottom: 10, right: 10),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HtmlEditorExample(
                          title: 'Create FAQ',
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
            body: Container(
              color: AppCommonTheme.backgroundColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.requireData.length,
                itemBuilder: (BuildContext context, int index) {
                  return FaqListItem(
                    client: client,
                    faq: snapshot.requireData[index],
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
