import 'dart:async';

/// Refresh open lifecycle panels after an assignment editor saves successfully.
class TenantLifecycleChanges {
  static final _changes =
      StreamController<({String project, String tenant})>.broadcast();
  static Stream<({String project, String tenant})> get stream =>
      _changes.stream;
  static void groupsSaved(String project, String tenant) =>
      _changes.add((project: project, tenant: tenant));
}
