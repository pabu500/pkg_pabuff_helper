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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.build, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'We are currently performing maintenance on the portal to serve you better.\nPlease check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
