import 'package:flutter/material.dart';

import '../../xt_helpers.dart';

class EmptyResult extends StatelessWidget {
  final String message;
  final double height;
  final double width;
  const EmptyResult(
      {Key? key, required this.message, this.height = 80, this.width = 160})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: height,
        width: width,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // mainAxisSize: MainAxisSize.min,
            children: [
              verticalSpaceSmall,
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/data_not_found.png"),
                    opacity: 0.62,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              verticalSpaceSmall,
              Text(
                message,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            ]),
      ),
    );
  }
}

void showSnackBar(BuildContext context, String s) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(s),
    duration: const Duration(seconds: 3),
  ));
}
