import 'package:flutter/material.dart';

class MySafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar  ;
  final Widget body;
  final Color? backgroundColor;

  const MySafeScaffold({this.appBar,this.backgroundColor,this.extendBodyBehindAppBar = false, required this.body});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        body: body,
      ),
    );
  }
}
