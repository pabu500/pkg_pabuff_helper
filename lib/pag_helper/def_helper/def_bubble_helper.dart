Map<String, int> calcBubbleValue(Map<String, dynamic> bubbleInfo) {
  int? totalCountSum;
  int? typeIssueCountSum;
  int? unknownCountSum;
  int? normalCountSum;
  for (var key in bubbleInfo.keys) {
    Map<String, dynamic> bubbleTypeInfo = bubbleInfo[key];
    int normalCount = bubbleTypeInfo['normal_count'];
    int unknownCount = bubbleTypeInfo['unknown_count'];
    int typeIssueCount = bubbleTypeInfo['type_issue_count'];
    int totalCount = normalCount + unknownCount + typeIssueCount;
    totalCountSum = totalCountSum ?? 0 + totalCount;
    normalCountSum = normalCountSum ?? 0 + normalCount;
    typeIssueCountSum = typeIssueCountSum ?? 0 + typeIssueCount;
    unknownCountSum = unknownCountSum ?? 0 + unknownCount;
  }

  return {
    'totalCountSum': totalCountSum ?? -1,
    'normalCountSum': normalCountSum ?? -1,
    'typeIssueCountSum': typeIssueCountSum ?? -1,
    'unknownCountSum': unknownCountSum ?? -1,
  };
}
