// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import 'package:xt_ui/xt_ui.dart';

// class xt_pg_info extends StatelessWidget {
//   xt_pg_info(
//       {Key? key,
//       this.icon,
//       this.title,
//       this.subtitle,
//       this.info,
//       // this.xtTextFiled,
//       this.showButton,
//       this.buttonText,
//       this.destPage})
//       : super(key: key);

//   IconData? icon;
//   String? title;
//   String? subtitle;
//   String? info;
//   // xtTextField? xtTextFiled;
//   bool? showButton;
//   String? buttonText;
//   String? destPage;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: Text('Public Front'),
//       // ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 80),
//         child: Center(
//           child: Column(
//             // mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               verticalSpaceMedium,
//               Icon(
//                 icon ?? Icons.info,
//                 size: 89,
//                 color: xtLightGreen2,
//               ),
//               if (title != null)
//                 Text(
//                   title ?? '',
//                   style: TextStyle(fontSize: 34),
//                 ),
//               verticalSpaceMedium,
//               if (subtitle != null)
//                 Text(
//                   subtitle ?? '',
//                   style: TextStyle(fontSize: 28),
//                 ),
//               verticalSpaceMedium,
//               Text(info ?? '',
//                   style: TextStyle(fontSize: 18), textAlign: TextAlign.justify),
//               verticalSpaceSmall,
//               if (showButton ?? false)
//                 xtButton(
//                   text: buttonText ?? 'Home',
//                   width: 210,
//                   onPressed: () => context.go(destPage ?? '/'),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
