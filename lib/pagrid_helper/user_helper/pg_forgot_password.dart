import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PgForgotPassword extends StatelessWidget {
  const PgForgotPassword({
    super.key,
    required this.supportEmail,
  });

  final String supportEmail;

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
              if (supportEmail.isNotEmpty) const Text('Please email to'),
              if (supportEmail.isNotEmpty) verticalSpaceTiny,
              if (supportEmail.isNotEmpty) Text(supportEmail),
              if (supportEmail.isEmpty)
                const Text('Please contact your administrator'),
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
