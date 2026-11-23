import 'package:buff_helper/pag_helper/comm/comm_list.dart';
import 'package:buff_helper/pag_helper/comm/comm_meter.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/up_helper/exceptions.dart';
import 'package:material_ui/material_ui.dart';

class WgtCreatePdmDevice extends StatefulWidget {
  const WgtCreatePdmDevice({
    super.key,
    required this.appConfig,
    required this.user,
    required this.category,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser user;
  final PagDeviceCat category;
  final VoidCallback? onCreated;

  @override
  State<WgtCreatePdmDevice> createState() => _WgtCreatePdmDeviceState();
}

class _WgtCreatePdmDeviceState extends State<WgtCreatePdmDevice> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, String>{};
  late final _fields = _getFields();

  bool _saving = false;
  String? _createdName;
  String? _error;

  MdlPagSvcClaim _claim() => MdlPagSvcClaim(
    userId: widget.user.id,
    username: widget.user.username,
    roleId: widget.user.selectedRole?.id,
    roleName: widget.user.selectedRole?.name,
    roleLabel: widget.user.selectedRole?.label,
    scope: '',
    target: '',
    operation: '',
  );

  Future<List<MdlListColController>> _getFields() async {
    final result = await getListInfoList2(widget.appConfig, widget.user, {
      'scope': widget.user.selectedScope.toScopeMap(),
      'item_kind': PagItemKind.device.value,
      'item_type': widget.category.value,
      'op': 'form_create',
    }, _claim()) as List<dynamic>;
    final config = result.single['list_config'] as List<dynamic>;
    final fields = [
      for (final column in config)
        MdlListColController.fromJson(column as Map<String, dynamic>),
    ].where((field) => field.opInfo != null).toList();
    if (fields.isEmpty) throw StateError('No device creation fields available');
    return fields;
  }

  Future<void> _create() async {
    if (_saving || _createdName != null || !_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await doPagCreateDevice(widget.user, widget.appConfig, {
        'scope': widget.user.selectedScope.toScopeMap(),
        'device_cat': widget.category.value,
        for (final entry in _values.entries)
          if (entry.value.isNotEmpty) entry.key: entry.value,
      }, _claim());
      if (!mounted) return;
      setState(() => _createdName = result['name'] as String);
      widget.onCreated?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = getErrorText(
          error,
          defaultErrorText: 'Could not create device',
        );
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 395,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<MdlListColController>>(
            future: _fields,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  getErrorText(
                    snapshot.error,
                    defaultErrorText: 'Could not load device fields',
                  ),
                );
              }
              final fields = snapshot.data;
              if (fields == null) return const LinearProgressIndicator();
              if (_createdName case final name?) return Text('Created $name');
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create ${widget.category.label}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final field in fields)
                      TextFormField(
                        enabled: !_saving,
                        decoration: InputDecoration(labelText: field.colTitle),
                        validator: (value) => getPdmDeviceValidator(
                          field.colKey,
                          isValueRequired:
                              field.opInfo?['is_value_required'] != 'false',
                        )(value?.trim() ?? ''),
                        onSaved: (value) =>
                            _values[field.colKey] = value?.trim() ?? '',
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : _create,
                      child: Text(_saving ? 'Creating…' : 'Create'),
                    ),
                    if (_error case final message?) Text(message),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
