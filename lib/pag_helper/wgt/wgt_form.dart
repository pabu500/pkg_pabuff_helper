import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class WgtForm extends StatefulWidget {
  const WgtForm({
    super.key,
    this.onUpdate,
    this.onSubmit,
    this.onInsert,
    this.onClose,
    required this.onResult,
    required this.fieldConfig,
    this.submitText = 'Submit',
    this.showRemove = false,
    this.onRemove,
    this.compactViewOnly = false,
    this.showBorder = true,
    this.width = 360,
  });

  final String submitText;
  final Function? onUpdate;
  final Function? onSubmit;
  final Function? onInsert;
  final Function? onClose;
  final void Function(String) onResult;
  final List<Map<String, dynamic>> fieldConfig;
  final bool showRemove;
  final Function? onRemove;
  final bool compactViewOnly;
  final bool showBorder;
  final double width;

  @override
  State<WgtForm> createState() => _WgtFormState();
}

class _WgtFormState extends State<WgtForm> {
  // late final double _width = 360;

  bool _isEditMode = false;
  bool _isCompactViewOnly = false;
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a `GlobalKey<SignUpBasicFormState>`.
  final _formKey = GlobalKey<FormState>();
  // Form is dirty when it has been submitted at least once
  bool _isFormDirty = false;
  // To keep track of form states
  bool _isSubmittingForm = false;
  // To keep track of field errors
  bool _isAsyncErro1 = false;
  bool _isAsyncError2 = false;
  bool
      get _hasAsyncErrors => // _isEmailAlreadyRegistered || _isUsernameAlreadyTaken;
          _isAsyncErro1 || _isAsyncError2;

  String _resultStr = '';

  void _setIsFormDirty(bool value) {
    setState(() {
      _isFormDirty = value;
    });
  }

  void _setIsSubmittingForm(bool value) {
    setState(() {
      _isSubmittingForm = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.fieldConfig
        .any((element) => (element['initialValue'] ?? {}).isNotEmpty);

    _isCompactViewOnly = widget.compactViewOnly && _isEditMode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: !widget.showBorder
          ? null
          : BoxDecoration(
              border: Border.all(
                color: Theme.of(context).hintColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
      padding:
          !widget.showBorder ? null : const EdgeInsets.symmetric(vertical: 5),
      child: Form(
        key: _formKey,
        // to keep the form unvalidated
        // until user has submitted the form once
        autovalidateMode: _isFormDirty
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var field in widget.fieldConfig)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _isCompactViewOnly || (field['isReadOnly'] ?? false)
                    ? xtKeyValueText(
                        keyText: field['label'],
                        valueText: field['initialValue'] ?? '',
                        keyWidth: 80,
                        // valueWidth: 80,
                      )
                    : TextFormField(
                        maxLines: 1,
                        maxLength: field['maxLength'],
                        decoration: InputDecoration(
                          labelText: field['label'],
                          labelStyle: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                          hintText: field['hint'],
                          hintStyle: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                          border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).hintColor)),
                          errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error)),
                          focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).hintColor)),
                        ),
                        initialValue: field['initialValue'],
                        validator: field['validator'] ??
                            (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                        onSaved: field['onSaved'],
                      ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.showRemove)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      widget.onRemove?.call();
                    },
                  ),
                Expanded(child: Container()),
                _isCompactViewOnly
                    ? IconButton(
                        icon: Icon(Icons.edit,
                            color: Theme.of(context).colorScheme.primary),
                        onPressed: () {
                          setState(() {
                            _isCompactViewOnly = false;
                          });
                        },
                      )
                    : widget.onInsert != null
                        ? getInsertButton()
                        : WgtCommButton(
                            label: widget.submitText,
                            inComm: _isSubmittingForm,
                            onPressed: () async {
                              String resultStatus = _isEditMode
                                  ? await widget.onUpdate?.call()
                                  : await widget.onSubmit?.call();

                              return resultStatus;
                            },
                            onResult: (result) {
                              String resultStr = '';
                              if (result != null && result is String) {
                                setState(() {
                                  _resultStr = result;
                                });
                              }
                              widget.onResult.call(resultStr);
                            },
                          ),
                if (!_isCompactViewOnly && _isEditMode)
                  IconButton(
                      onPressed: () {
                        setState(() {
                          _isCompactViewOnly = true;
                        });
                      },
                      icon: Icon(Symbols.unfold_less,
                          color: Theme.of(context).colorScheme.primary)),
                horizontalSpaceTiny,
                if (!widget.showRemove)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      widget.onClose?.call();
                    },
                  ),
                horizontalSpaceSmall,
              ],
            ),
            if (_resultStr.isNotEmpty) getResult(),
            // verticalSpaceTiny,
          ],
        ),
      ),
    );
  }

  Widget getInsertButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: InkWell(
        onTap: () {
          widget.onInsert?.call();
        },
        child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text('Add')),
      ),
    );
  }

  Widget getResult() {
    bool _isSuccess = _resultStr.contains('added') ||
        _resultStr.contains('updated') ||
        _resultStr.contains('deleted');

    if (!_isSuccess) {
      return getErrorTextPrompt(
          context: context, errorText: 'Error submitting info');
    }
    Color resultColor = _isSuccess
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          _resultStr,
          style: TextStyle(
            color: resultColor,
          ),
        ),
      ),
    );
  }
}
