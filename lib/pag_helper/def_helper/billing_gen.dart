/// Build-time billing pipeline selector.
///
/// Use `--dart-define=billingGen=3` to compile the refactored route.
/// Builds without the define continue to use the current v2 route.
const int billingGen = int.fromEnvironment('billingGen', defaultValue: 2);

bool get useBillingGen3 {
  if (billingGen != 2 && billingGen != 3) {
    throw StateError('billingGen must be 2 or 3');
  }
  return billingGen == 3;
}
