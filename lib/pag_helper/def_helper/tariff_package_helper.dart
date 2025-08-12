import 'package:buff_helper/pag_helper/def_helper/pag_tariff_package_helper.dart';
import 'package:buff_helper/util/date_time_util.dart';

String validateTpRateList({
  required PagTariffPackageTypeCat tpTypeCat,
  required List<Map<String, dynamic>> rateList,
  required int tpComingMonthCount,
  required int timezone,
  bool isEdit = false,
}) {
  DateTime localNow = getTargetLocalDatetimeNow(timezone);

  for (var rateRow in rateList) {
    if (rateRow['from_datetime'] == null || rateRow['to_datetime'] == null) {
      return 'Invalid tariff rate list';
    }

    if (tpTypeCat == PagTariffPackageTypeCat.regular) {
      if (rateRow['rate'] == null) {
        return 'Invalid tariff rate';
      }
      dynamic rate = rateRow['rate'];
      if (rate is String) {
        rate = double.tryParse(rate);
        if (rate == null) {
          return 'Invalid tariff rate';
        }
      } else if (rate is! num) {
        return 'Invalid tariff rate';
      }
      if (rate < 0) {
        return 'Invalid tariff rate';
      }
    }

    DateTime fromDateTime = rateRow['from_datetime'];
    DateTime toDateTime = rateRow['to_datetime'];

    if (fromDateTime.isAfter(toDateTime)) {
      return '"From date" should be before "To date"';
    }

    // From month should be greater than the current month
    int minYear = localNow.year;
    int minMonth = localNow.month - 2;
    if (minMonth > 12) {
      minYear++;
      minMonth = minMonth - 12;
    }
    int fromYear = fromDateTime.year;
    int fromMonth = fromDateTime.month;
    if (!isEdit) {
      if (fromYear < minYear) {
        return '"From month" should be after $minYear-$minMonth';
      }
      if (fromYear == minYear && fromMonth < minMonth) {
        return '"From month" should be after $minYear-$minMonth';
      }
    }

    // the furtherest date should be greater than the _tpComingMonthCount
    int capYear = localNow.year;
    int capMonth = localNow.month + tpComingMonthCount;
    if (capMonth > 12) {
      capYear++;
      capMonth = capMonth - 12;
    }

    int toYear = toDateTime.year;
    int toMonth = toDateTime.month;

    if (toYear > capYear) {
      // return '"To month" should be before $capYear-$capMonth';
      return 'Cannot create tariff rate beyond $capYear-$capMonth';
    }
    if (toYear == capYear && toMonth > capMonth) {
      // return '"To month" should be before $capYear-$capMonth';
      return 'Cannot create tariff rate beyond $capYear-$capMonth';
    }
  }
  return 'valid';
}
