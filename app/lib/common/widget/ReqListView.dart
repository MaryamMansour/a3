// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';

class ReqListView extends StatelessWidget {
  const ReqListView({
    Key? key,
    required this.name,
  }) : super(key: key);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  name,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                          color: AppCommonTheme.greenButtonColor, fontSize: 16),
                    ),
                  ),
                  Text(
                    'Decline',
                    style: TextStyle(
                        color: AppCommonTheme.primaryColor, fontSize: 16),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
