import 'package:material_ui/material_ui.dart';
import 'package:buff_helper/pagrid_helper/batch_op_helper/wgt_confirm_box.dart';

class WgtPreviousSystemDebtorDialog extends StatelessWidget {
  const WgtPreviousSystemDebtorDialog({
    super.key,
    required this.tenantName,
    required this.bill,
    required this.serviceEndDate,
  });
  final String tenantName;
  final Map<String, dynamic> bill;
  final String serviceEndDate;
  @override
  Widget build(BuildContext context) {
    final phrase = 'convert $tenantName';
    return WgtConfirmBox(
      title: 'Conversion Confirmation',
      opName: 'convert_tenant',
      itemCount: 1,
      keyInConfirmStrList: [phrase],
      confirmResult: true,
      onConfirm: () {},
      footerWidget: SizedBox(
        width: 395,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opening bill: ${bill['label'] ?? ''}'),
            Text('Released: ${bill['bill_release_timestamp'] ?? ''}'),
            Text('Outstanding: ${bill['cycle_remaining_balance'] ?? ''}'),
            Text('Termination date: $serviceEndDate'),
            const Text(
              "The opening bill becomes the final bill. This can't be undone.",
            ),
          ],
        ),
      ),
    );
  }
}
