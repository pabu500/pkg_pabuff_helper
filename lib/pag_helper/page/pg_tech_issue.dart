import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class PgTechIssue extends StatelessWidget {
  const PgTechIssue({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 95),
          Container(
            height: 200,
            width: 350,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/energy_at_grid_logo.png"),
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Symbols.assignment_late,
                      size: 50,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    verticalSpaceSmall,
                    Text(
                      'Oops! Something went wrong. We are working on it.',
                      style: TextStyle(
                        fontSize: 21,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ));
  }
}
