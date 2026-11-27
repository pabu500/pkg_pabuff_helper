import '../../../../pag_helper/def_helper/dh_pag_tenant.dart';

const cwGiroNoteTitle = 'Note for GIRO tenants:';
const cwGiroNoteText =
    'If invoice due date falls on a non-business day, GIRO deduction (if applicable) will be processed on the next business day.';

bool cwShowsGiroNote(String paymentMethod) => paymentMethod == 'giro';

String cwPaymentModeLabel(String paymentMethod) {
  final method = PagPaymentMethod.byValue(paymentMethod);
  return method == PagPaymentMethod.giro ? 'GIRO' : method.label;
}
