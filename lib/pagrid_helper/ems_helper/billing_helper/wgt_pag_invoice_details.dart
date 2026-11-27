import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../pag_helper/def_helper/dh_device.dart';
import '../../../pag_helper/def_helper/dh_pag_bill.dart';
import '../../../util/string_util.dart';
import 'cw_bill/landlord_logo_cw.dart';
import 'cw_bill/payment_cw.dart';
import 'cw_bill/principal_address_cw.dart';

class WgtPagInvoiceDetails extends StatelessWidget {
  const WgtPagInvoiceDetails({super.key, required this.billInfo});

  final Map<String, dynamic> billInfo;

  static const _missing = '—';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentMethod = billInfo['payment_method']?.toString() ?? '';
    final deposit = billInfo['deposit_amount']?.toString() ?? '';
    final depositAmount = double.tryParse(deposit.replaceAll(',', ''));
    final singularRows = billInfo['singular_billing_rec_list'];
    final tariffRows = singularRows is List
        ? singularRows.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectionArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice details', style: theme.textTheme.titleLarge),
                if (billInfo['lc_status'] == PagBillingLcStatus.generated.value)
                  const Text('Current values — frozen when moved to PV'),
                const SizedBox(height: 16),
                _sections(constraints.maxWidth, [
                  _section(context, 'Payer', [
                    _field(
                      'Company trading name',
                      billInfo['customer_company_trading_name'],
                    ),
                    _field('Account number', billInfo['tenant_account_number']),
                    _field('Tenant label', billInfo['tenant_label']),
                    for (var line = 1; line <= 3; line++)
                      _field(
                        'Billing address line $line',
                        billInfo['tenant_billing_address_line_$line'],
                      ),
                  ]),
                  _section(context, 'Premises', [
                    _field('Principal address', cwPrincipalAddress(billInfo)),
                    for (var line = 1; line <= 3; line++)
                      _field(
                        'Building address line $line',
                        billInfo['tenant_building_address_line_$line'],
                      ),
                    _field('Location label', billInfo['tenant_location_label']),
                  ]),
                  _section(context, 'Biller (AMGR)', [
                    _field(
                      'Company trading name',
                      billInfo['billed_amgr_company_trading_name'],
                    ),
                    _field(
                      'Company reg. no.',
                      billInfo['billed_amgr_company_reg_number'],
                    ),
                    _field(
                      'GST reg. no.',
                      billInfo['billed_amgr_gst_reg_number'],
                    ),
                    _field('UEN', billInfo['billed_amgr_uen']),
                    for (var line = 1; line <= 3; line++)
                      _field(
                        'Address line $line',
                        billInfo['amgr_address_line_$line'],
                      ),
                    _fieldRow('Landlord logo', _landlordLogo()),
                  ]),
                  _section(context, 'Remittance', [
                    _field('Bank name', billInfo['amgr_bank_label']),
                    _field('Account name', billInfo['amgr_bank_account_name']),
                    _field(
                      'Account number',
                      billInfo['amgr_bank_account_number'],
                    ),
                    _field('Bank code', billInfo['amgr_bank_code']),
                    _field('Branch code', billInfo['amgr_bank_branch_code']),
                    _field('SWIFT code', billInfo['amgr_bank_swift_code']),
                    _field('PayNow', billInfo['amgr_bank_paynow']),
                  ]),
                  _section(context, 'Payment', [
                    _field(
                      'Deposit amount',
                      depositAmount != null && depositAmount.isFinite
                          ? '\$${getCommaNumberStr(depositAmount)}'
                          : deposit,
                    ),
                    _field(
                      'Payment mode',
                      paymentMethod.trim().isEmpty
                          ? null
                          : cwPaymentModeLabel(paymentMethod),
                    ),
                    if (cwShowsGiroNote(paymentMethod)) ...[
                      const SizedBox(height: 8),
                      Text(cwGiroNoteTitle, style: theme.textTheme.titleSmall),
                      const Text(cwGiroNoteText),
                    ],
                  ]),
                ]),
                const Divider(height: 32),
                Text('Tariff notes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (tariffRows.isEmpty)
                  const Text(_missing)
                else
                  _sections(constraints.maxWidth, [
                    for (final tariffRow in tariffRows)
                      _section(context, _tariffTitle(tariffRow), [
                        _field(
                          'Tariff package note 1',
                          tariffRow['billed_tp_note'],
                        ),
                        _field(
                          'Tariff package note 2',
                          tariffRow['billed_tp_note2'],
                        ),
                        _field('Rate note', tariffRow['billed_tpt_rate_note']),
                        _field(
                          'Cycle note',
                          tariffRow['billed_tpt_cycle_note'],
                        ),
                      ]),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _landlordLogo() {
    final logo = decodeLandlordLogoBytes(
      billInfo['landlord_logo_png_base64']?.toString(),
    );
    // The PDF's default logo is transparent; no custom logo means none is printed.
    if (logo == null) return const Text(_missing);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Image.memory(
        logo,
        height: 52,
        fit: BoxFit.contain,
        semanticLabel: 'Landlord logo preview',
        errorBuilder: (context, error, stackTrace) => const Text(_missing),
      ),
    );
  }

  String _tariffTitle(Map<String, dynamic> row) {
    var tag = row['meter_type']?.toString().trim().toUpperCase() ?? '';
    if (tag.isEmpty) {
      // Legacy singular rows only expose type-specific tariff IDs.
      final tags = ['e', 'w', 'b', 'n', 'g'].where((type) {
        final rateId = row['tariff_rate_id_$type']?.toString().trim();
        return rateId != null && rateId.isNotEmpty;
      });
      if (tags.length == 1) tag = tags.single.toUpperCase();
    }
    final type = PagMeterType.byTag(tag);
    final label = type == PagMeterType.unknown
        ? (tag.isEmpty ? _missing : tag)
        : type.label;
    final from = DateTime.tryParse(row['from_timestamp']?.toString() ?? '');
    final to = DateTime.tryParse(row['to_timestamp']?.toString() ?? '');
    if (from == null || to == null) return label;
    final date = DateFormat('dd MMM yyyy');
    final lastDay = to.subtract(const Duration(seconds: 1));
    return '$label (${date.format(from)} – ${date.format(lastDay)})';
  }

  Widget _sections(double width, List<Widget> sections) {
    const spacing = 24.0;
    final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
    final sectionWidth = (width - (columns - 1) * spacing) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: 16,
      children: [
        for (final section in sections)
          SizedBox(width: sectionWidth, child: section),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> fields) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ...fields,
        ],
      );

  Widget _field(String label, Object? value) {
    final text = value?.toString().trim() ?? '';
    return _fieldRow(label, Text(text.isEmpty ? _missing : text));
  }

  Widget _fieldRow(String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Text(label)),
        const SizedBox(width: 8),
        Expanded(flex: 6, child: value),
      ],
    ),
  );
}
