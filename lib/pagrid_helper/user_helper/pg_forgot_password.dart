import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PgForgotPassword extends StatelessWidget {
  const PgForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.primary, width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 34),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Forgot Password?',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor),
              ),
              verticalSpaceSmall,
              const Text('Please email to'),
              verticalSpaceTiny,
              const Text('evs_operator@yahoo.com.sg'),
              verticalSpaceTiny,
              const Text('for assistance.'),
              verticalSpaceMedium,
              ElevatedButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
