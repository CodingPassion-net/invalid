import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invalid/invalid.dart';

class ValidationFormWidget<KeyType> extends StatelessWidget {
  final Iterable<Field<KeyType>> fields;
  final Iterable<FormValidator<KeyType, FormValidator>> formValidators;
  final Function(FormValidationState<KeyType>) onFormTurnedValid;
  final Function(FormValidationState<KeyType>) onFormTurnedInValid;
  final Function(FormValidationState<KeyType>) onUpdate;
  final Function(FormValidationCubit<KeyType>) onFormValidationCubitCreated;
  final Widget child;
  final bool enabled;
  const ValidationFormWidget(
      {Key key,
      this.fields,
      this.enabled = false,
      this.formValidators,
      this.onUpdate,
      @required this.child,
      this.onFormTurnedValid,
      this.onFormTurnedInValid,
      this.onFormValidationCubitCreated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FormValidationCubit<KeyType>>(
      create: (BuildContext context) {
        var formValidationCubit = FormValidationCubit<KeyType>(
            FormValidationState<KeyType>(
                enabled: enabled,
                fields: fields,
                formValidators: formValidators));
        onFormValidationCubitCreated?.call(formValidationCubit);
        return formValidationCubit;
      },
      child: BlocListener<FormValidationCubit<KeyType>,
          FormValidationState<KeyType>>(
        listener: (_, state) {
          return onUpdate?.call(state);
        },
        child: BlocListener<FormValidationCubit<KeyType>,
            FormValidationState<KeyType>>(
          listenWhen: (previousState, currentState) =>
              onFormTurnedValid != null &&
              !previousState.isValid &&
              currentState.isValid,
          listener: (BuildContext context, state) {
            onFormTurnedValid?.call(state);
          },
          child: BlocListener<FormValidationCubit<KeyType>,
              FormValidationState<KeyType>>(
            child: child,
            listenWhen: (previousState, currentState) =>
                onFormTurnedInValid != null &&
                previousState.isValid &&
                !currentState.isValid,
            listener: (BuildContext context, state) {
              onFormTurnedInValid?.call(state);
            },
          ),
        ),
      ),
    );
  }
}

FormValidationCubit<KeyType> getForm<KeyType>(BuildContext context) {
  return BlocProvider.of<FormValidationCubit<KeyType>>(context);
}

FormValidationCubit<KeyType> addFieldAndGetForm<KeyType>(
    Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators,
    KeyType key,
    BuildContext context,
    {String fieldName}) {
  if (key == null) return null;
  var formValidationBloc =
      BlocProvider.of<FormValidationCubit<KeyType>>(context);
  formValidationBloc.addField(
      Field<KeyType>(key: key, validators: validators, fieldName: fieldName));
  return formValidationBloc;
}

class ValidationCapability<KeyType> {
  FormValidationCubit<KeyType> _formValidationBloc;
  final KeyType validationKey;
  final List<FieldValidator<dynamic, KeyType, dynamic>> _validators;
  final String fieldName;

  ValidationCapability(
      {@required this.validationKey,
      this.fieldName,
      Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators =
          const []})
      : _validators = validators.toList();

  void init(BuildContext context) {
    _formValidationBloc = addFieldAndGetForm<KeyType>(
        _validators, validationKey, context,
        fieldName: fieldName);
  }

  void addUpdateFieldEvent(newVal) {
    if (_formValidationBloc == null) {
      throw UninitializedException<KeyType>();
    }
    _formValidationBloc.updateField(validationKey, newVal);
  }

  ValidationCapability<KeyType> copyWith(
      {KeyType validationKey,
      List<FieldValidator<dynamic, KeyType, dynamic>> validators,
      String fieldName}) {
    return ValidationCapability<KeyType>(
        fieldName: fieldName ?? this.fieldName,
        validators: validators ?? [..._validators],
        validationKey: validationKey ?? this.validationKey);
  }
}

class TextValidationCapability<KeyType> extends ValidationCapability<KeyType> {
  TextEditingController _controller;
  final bool autoValidate;

  TextValidationCapability(
      {@required KeyType validationKey,
      String fieldName,
      Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators = const [],
      this.autoValidate = true})
      : super(
            validationKey: validationKey,
            validators: validators,
            fieldName: fieldName);

  @override
  void init(BuildContext context,
      {@required TextEditingController controller}) {
    super.init(context);
    _controller = controller;
    updateTextField();
    if (autoValidate) _controller?.addListener(updateTextField);
  }

  void updateTextField() {
    super.addUpdateFieldEvent(_controller.text);
  }
}

class UninitializedException<KeyType> implements Exception {
  @override
  String toString() {
    return "UninitializedException: ValidatorCapability was used before calling init(BuildContext context) "
        "or was not initialized inside a context which contains a FormValidationBloc of type ${KeyType.runtimeType}";
  }
}
