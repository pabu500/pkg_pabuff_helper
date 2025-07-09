/* page for manteinance notice 
 * 
*/

import 'package:flutter/material.dart';

class PgPortalMaint extends StatelessWidget {
  const PgPortalMaint({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Maintenance'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.build,
              size: 120,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'We are currently performing maintenance on the portal to serve you better.\nPlease check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 21,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
