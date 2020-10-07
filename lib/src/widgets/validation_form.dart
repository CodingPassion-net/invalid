import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invalid/invalid.dart';

class ValidationForm<KeyType> extends StatelessWidget {
  final Iterable<FormValidator<KeyType, FormValidator>> formValidators;

  /// Will be called once the form turns from invald to valid.
  /// But be aware, fields (therefor also validatores) can be removed asynchronously.
  /// When you remove all fields (therefor also validatores) the form turns valid and this callback is called.
  final Function(FormValidationState<KeyType>) onFormTurnedValid;

  /// Will be called once the form turns from valid to invalid.
  /// But be aware, fields (therefor also validatores) are added asynchronously (for example in initState of TextField),
  /// which means, that the form is valid at the beginning and once you add fields it can turn invalid.
  /// That's why it can happen that this callback is called immediately, after adding fields.
  final Function(FormValidationState<KeyType>) onFormTurnedInValid;

  /// [onUpdate] will be called when the state of [FormValidationState] changes.
  final Function(FormValidationState<KeyType>) onUpdate;
  final Function(FormValidationCubit<KeyType>) onFormValidationCubitCreated;

  /// If true, the validation messages are shown immediately, if false it must be enabled before.
  /// Use case for this is when you have a form, and you want validation messages to appear after the user
  /// has clicked the submit button.
  final bool enabled;
  final Widget child;
  const ValidationForm(
      {Key key,
      @required this.child,
      this.enabled = false,
      this.formValidators,
      this.onUpdate,
      this.onFormTurnedValid,
      this.onFormTurnedInValid,
      this.onFormValidationCubitCreated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FormValidationCubit<KeyType>>(
      create: (BuildContext context) {
        var formValidationCubit = FormValidationCubit<KeyType>(
            FormValidationState<KeyType>(enabled: enabled, formValidators: formValidators));
        onFormValidationCubitCreated?.call(formValidationCubit);
        return formValidationCubit;
      },
      child: BlocListener<FormValidationCubit<KeyType>, FormValidationState<KeyType>>(
        listener: (_, state) {
          return onUpdate?.call(state);
        },
        child: BlocListener<FormValidationCubit<KeyType>, FormValidationState<KeyType>>(
          listenWhen: (previousState, currentState) =>
              onFormTurnedValid != null && !previousState.isValid && currentState.isValid,
          listener: (BuildContext context, state) {
            onFormTurnedValid?.call(state);
          },
          child: BlocListener<FormValidationCubit<KeyType>, FormValidationState<KeyType>>(
            child: child,
            listenWhen: (previousState, currentState) =>
                onFormTurnedInValid != null && previousState.isValid && !currentState.isValid,
            listener: (BuildContext context, state) {
              onFormTurnedInValid?.call(state);
            },
          ),
        ),
      ),
    );
  }
}

extension BuildContextExtensions on BuildContext {
  FormValidationCubit<KeyType> getForm<KeyType>() => BlocProvider.of<FormValidationCubit<KeyType>>(this);
}

class ValidationCapability<KeyType> {
  FormValidationCubit<KeyType> _formValidationBloc;
  KeyType validationKey;
  List<FieldValidator<dynamic, KeyType, dynamic>> validators;
  String fieldName;

  ValidationCapability(
      {@required this.validationKey,
      this.fieldName,
      Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators = const []})
      : validators = validators.toList();

  void init(BuildContext context) {
    _formValidationBloc = _addFieldAndGetForm(validators, validationKey, context, fieldName: fieldName);
  }

  FormValidationCubit<KeyType> _addFieldAndGetForm(
      Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators, KeyType key, BuildContext context,
      {String fieldName}) {
    if (key == null) return null;
    var formValidationBloc = BlocProvider.of<FormValidationCubit<KeyType>>(context);
    formValidationBloc.addField(Field<KeyType>(key: key, validators: validators, fieldName: fieldName));
    return formValidationBloc;
  }

  void addUpdateFieldEvent(dynamic newVal) {
    if (_formValidationBloc == null) {
      throw UninitializedException<KeyType>();
    }
    _formValidationBloc.updateField(validationKey, newVal);
  }
}

class TextValidationCapability<KeyType> extends ValidationCapability<KeyType> {
  TextEditingController _controller;
  bool autoValidate;

  TextValidationCapability(
      {@required KeyType validationKey,
      String fieldName,
      Iterable<FieldValidator<dynamic, KeyType, dynamic>> validators = const [],
      this.autoValidate = true})
      : super(validationKey: validationKey, validators: validators, fieldName: fieldName);

  @override
  void init(BuildContext context, {@required TextEditingController controller}) {
    super.init(context);
    _controller = controller;
    addUpdateFieldEvent(_controller.text);
    if (autoValidate) _controller?.addListener(() => addUpdateFieldEvent(_controller.text));
  }
}

class UninitializedException<KeyType> implements Exception {
  @override
  String toString() {
    return "UninitializedException: ValidatorCapability was used before calling init(BuildContext context) "
        "or was not initialized inside a context which contains a FormValidationBloc of type ${KeyType.runtimeType}";
  }
}
