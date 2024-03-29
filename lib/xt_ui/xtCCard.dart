import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class xtCCard extends StatelessWidget {
  xtCCard({Key? key, required this.brand}) : super(key: key);

  String brand;
  @override
  Widget build(BuildContext context) {
    String brandIcon = '';
    switch (brand) {
      case 'visa':
        brandIcon = 'assets/images/cards/visa.svg';
        break;
      case 'mastercard':
        brandIcon = 'assets/images/cards/mastercard.svg';
        break;
      case 'unionpay':
        brandIcon = 'assets/images/cards/unionpay.svg';
        break;
      case 'amex':
        brandIcon = 'assets/images/cards/amex.svg';
        break;
      case 'jcb':
        brandIcon = 'assets/images/cards/jcb.svg';
        break;
      case 'diners':
        brandIcon = 'assets/images/cards/diners.svg';
        break;
      case 'discover':
        brandIcon = 'assets/images/cards/discover.svg';
        break;
      default:
        brandIcon = 'assets/images/cards/visa.svg';
    }
    return SizedBox(
      // height: 34,
      width: 55,
      child: SvgPicture.asset(
        brandIcon,
        // colorFilter: ColorFilter.mode(
        // Theme.of(context).colorScheme.secondary, BlendMode.srcIn)
      ),
    );
  }
}
